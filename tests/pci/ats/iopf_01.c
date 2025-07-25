/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Copyright (c) 2025 Samsung Electronics Co., Ltd. All Rights Reserved.
 *
 * Written by Joel Granados <joel.granados@kernel.org>
 */
#include <linux/iommufd.h>

#include <vfn/vfio.h>
#include <vfn/iommu/iommufd.h>
#include <vfn/iommu/dma.h>
#include <vfn/support.h>

#include <ccan/opt/opt.h>
#include <ccan/err/err.h>

#include <string.h>
#include <inttypes.h>
#include <sys/mman.h>

#define REG_ADDR 0x0
#define REG_CMD  0x8
#define IOVA_BASE 0xfef00000

bool show_usage;
char *bdf = "";
struct vfio_pci_device pdev;

struct opt_table iopf_01_options[] = {
	OPT_WITHOUT_ARG("-h|--help", opt_set_bool, &show_usage, "show usage"),
	OPT_WITH_ARG("-d|--device BDF", opt_set_charp, opt_show_charp, &bdf, "pci device"),
	OPT_ENDTABLE,
};

void parse_options(int argc, char **argv)
{
	opt_register_table(iopf_01_options, NULL);
	opt_parse(&argc, argv, opt_log_stderr_exit);

	if (show_usage)
		opt_usage_exit_fail(NULL);

	if (strcmp((bdf), ("")) == 0)
		opt_usage_exit_fail(": Missing -d|--device parameter");

	opt_free_table();
}

int main(int argc, char **argv)
{
	void *bar0;
	uint64_t iova = IOVA_BASE;
	ssize_t len;
	void *vaddr;

	struct iommufd_fault_queue fq;
	struct iommu_hwpt_pgfault pgfault;
	struct iommu_hwpt_page_response pgresp = {
		.code = IOMMUFD_PAGE_RESP_SUCCESS,
	};

	parse_options(argc, argv);

	fprintf(stdout, "Testing IO Page Fault on device %s\n", bdf);

	if (vfio_pci_open(&pdev, bdf))
		err(1, "failed to open pci device");

	/* Allocate fault queue for handling page faults */
	if (iommufd_alloc_fault_queue(&fq))
		err(1, "could not allocate fault queue");

	/* Associate fault queue with device/ioas */
	if (iommufd_set_fault_queue(pdev.dev.ctx, &fq, pdev.dev.fd))
		err(1, "could not associate fault queue with device/ioas");

	bar0 = vfio_pci_map_bar(&pdev, 0, 0x1000, 0, PROT_READ | PROT_WRITE);
	if (!bar0)
		err(1, "failed to map bar");

	len = pgmap(&vaddr, 0x1000);
	if (len < 0)
		err(1, "could not allocate aligned memory");

	/* Initialize memory with test pattern */
	memset(vaddr, 0x42, 0x1000);

	/* Set the iova address in device - this will trigger a page fault */
	mmio_lh_write64(bar0 + REG_ADDR, iova);
	mmio_write32(bar0 + REG_CMD, 0x3);

	/* Fail if fault does not happen within 2 seconds*/
	for (int i = 0; i <= 20 && read(fq.fault_fd, &pgfault, sizeof(pgfault)) == 0; ++i) {
		if (i == 20)
			err(1, "Could not handle page fault");
		usleep(100000);
	}

	/* Map the page after receiving the fault */
	if (iommu_map_vaddr(pdev.dev.ctx, vaddr, 0x1000, &iova, IOMMU_MAP_FIXED_IOVA))
		err(1, "failed to map page");

	/* Send page response */
	pgresp.cookie = pgfault.cookie;
	if (write(fq.fault_fd, &pgresp, sizeof(pgresp)) < 0)
		err(1, "failed to write page response");

	/* Wait for command completion */
	while (mmio_read32(bar0 + REG_CMD) & 0x1)
		;

	/* Clear memory to validate the test */
	memset(vaddr, 0x0, 0x1000);

	/* Send command to transfer device value back to memory */
	mmio_write32(bar0 + REG_CMD, 0x1);

	/* Wait for command completion */
	while (mmio_read32(bar0 + REG_CMD) & 0x1)
		;

	/* Verify the data was correctly transferred */
	for (int i = 0; i < 0x1000; i++) {
		uint8_t byte = *(uint8_t *)(vaddr + i);

		if (byte != 0x42)
			errx(1, "unexpected byte 0x%"PRIx8" at offset %d", byte, i);
	}

	return 0;
}
