import subprocess
import os.path
import pprint
import pytest

test_exec = os.path.join(os.path.dirname(__file__), "dma_01")
def dma_01(bdf):
    cmd = [test_exec, "--device", bdf]
    result = subprocess.run(cmd ,stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    pprint.pprint (result.__dict__)
    return result.returncode == 0

@pytest.mark.parametrize("check_file", [test_exec])
@pytest.mark.parametrize(
        "pci_dev_enumer",
        [{"device": "0x11e9", "vendor": "0x1234"}],
        indirect = True)
def test_dma_01(capsys, check_file, pci_dev_enumer, bind_to_vfio_pci):
    pci_dev_list = list(pci_dev_enumer)
    if len(pci_dev_list) < 1:
        pytest.skip("No devices found for these parameters")

    for pci_dev in pci_dev_enumer:
        print(pci_dev)
        bind_to_vfio_pci(pci_dev)
        assert dma_01(pci_dev.sys_name) == True

    print (capsys.readouterr())

