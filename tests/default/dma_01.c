#include <vfn/vfio.h>
#include <vfn/iommu.h>
#include <vfn/iommu/iommufd.h>
#include <vfn/support.h>

#include <ccan/opt/opt.h>
#include <ccan/err/err.h>

#include <string.h>
#include <inttypes.h>

#define REG_ADDR 0x0
#define REG_CMD  0x8
#define IOVA_BASE 0xfef00000

bool show_usage;
char *bdf = "";
struct vfio_pci_device pdev;

struct opt_table dma_01_options[] = {
	OPT_WITHOUT_ARG("-h|--help", opt_set_bool, &show_usage, "show usage"),
	OPT_WITH_ARG("-d|--device BDF", opt_set_charp, opt_show_charp, &bdf, "pci device"),
	OPT_ENDTABLE,
};

void dma_01_exit(const char *fmt, ...)
{
	exit(1);
}

void parse_options(int argc, char **argv)
{
	opt_register_table(dma_01_options, NULL);
	opt_parse(&argc, argv, dma_01_exit);

	if (show_usage)
		opt_usage_exit_fail(NULL);

	if (strcmp((bdf), ("")) == 0)
		opt_usage_exit_fail(": Missing -d|--device parameter");

	opt_free_table();
}

int main(int argc, char **argv)
{
	void *bar0;
	void *vaddr;
	uint64_t iova = IOVA_BASE;

	parse_options(argc, argv);
	fprintf(stdout, "first output\n");
	fprintf(stdout, "This is device %s\n", bdf);

	if (vfio_pci_open(&pdev, bdf))
		err(1, "failed to open pci device");

	bar0 = vfio_pci_map_bar(&pdev, 0, 0x1000, 0, PROT_READ | PROT_WRITE);
	if (!bar0)
		err(1, "failed to map bar");

	if (pgmap(&vaddr, 0x1000) < 0)
		err(1, "could not allocate aligned memory");
	memset(vaddr, 0x42, 0x1000);

	if (iommu_map_vaddr(pdev.dev.ctx, vaddr, 0x1000, &iova, IOMMU_MAP_FIXED_IOVA))
		err(1, "failed to map page");

	/* Set the iova address in device */
	mmio_lh_write64(bar0 + REG_ADDR, iova);

	/* Send command to transfer current value in vaddr to pcie device */
	mmio_write32(bar0 + REG_CMD, 0x3);

	/* Wait for write */
	while (mmio_read32(bar0 + REG_CMD) & 0x1)
		;

	/* Make sure to change the vaddr so the test is valid */
	memset(vaddr, 0x0, 0x1000);

	/* Send command to transfer current device value into vaddr */
	mmio_write32(bar0 + REG_CMD, 0x1);

	/* Wait for write */
	while (mmio_read32(bar0 + REG_CMD) & 0x1)
		;

	/* Do comparison */
	for (int i = 0; i < 0x1000; i++) {
		uint8_t byte = *(uint8_t *)(vaddr + i);

		if (byte != 0x42)
			errx(1, "unexpected byte 0x%"PRIx8, byte);
	}

	return 0;
}
