import os.path
import pytest

test_exec = os.path.join(os.path.dirname(__file__), "iopf_01")

@pytest.fixture(scope="function", autouse=True)
def pre_check(check_file, check_iommu_groups, check_iommufd):
    """Pre-flight checks for IOPF test requirements."""
    check_file(test_exec)
    check_iommu_groups()
    check_iommufd()

@pytest.mark.parametrize("pci_dev_enumer",
        [{"device": "0x11e9", "vendor": "0x1234"}],
        indirect = True)
def test_iopf_01(capsys, setup_and_teardown, exec_cmd):
    """Test IO Page Fault handling functionality."""
    pci_enumer = setup_and_teardown
    for pci_dev in pci_enumer:
        cmd = [test_exec, "--device", pci_dev.sys_name]
        assert exec_cmd(cmd) == True

    print(capsys.readouterr())
