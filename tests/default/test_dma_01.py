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

@pytest.fixture(scope="function", autouse=True)
def pre_check(check_file):
    check_file(test_exec)

@pytest.fixture
def setup_and_teardown(pci_dev_enumer, mod_binding_vfio_pci):
    pci_enumer = pci_dev_enumer
    if len(list(pci_enumer)) < 1:
        pytest.skip("No devices found for these parameters")

    for pci_dev in pci_enumer:
        mod_binding_vfio_pci(pci_dev)

    yield pci_enumer

    for pci_dev in pci_enumer:
        mod_binding_vfio_pci(pci_dev, unbind_only=True)

@pytest.mark.parametrize( "pci_dev_enumer",
        [{"device": "0x11e9", "vendor": "0x1234"}],
        indirect = True)
def test_dma_01(capsys, setup_and_teardown):
    pci_enumer = setup_and_teardown
    for pci_dev in pci_enumer:
        assert dma_01(pci_dev.sys_name) == True

    print (capsys.readouterr())

