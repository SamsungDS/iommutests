import pytest
import pyudev
import os
import os.path

sys_pci_ctx =  pyudev.Context()

@pytest.fixture
def check_file(request):
    file_path = request.param
    if not os.path.exists(file_path):
        pytest.skip("Skipping test: {file_path} is missing")
    return file_path

@pytest.fixture
def pci_dev_enumer(request):
    if not isinstance(request.param, dict):
        pytest.fail("Argument to get_pci_enumer must be a dictionary")
    if len(request.param) < 1:
        pytest.fail("Dictionary argument must have at least one element")

    dev_enumer = sys_pci_ctx.list_devices(subsystem = "pci")
    for key,val in request.param.items():
        dev_enumer = dev_enumer.match_attribute(key, val)

    return dev_enumer

def do_bind_to_vfio_pci(dev):
    if not isinstance(dev, pyudev.Device):
        pytest.fail("Arg to bind_to_vfio_pci must be a pyudev Device")

    vfio_pci_syspath = "/sys/bus/pci/drivers/vfio-pci"
    if not os.path.isdir(vfio_pci_syspath):
        # Incorrect environment is not a failure. Skip with an informative message
        pytest.skip(f"Path not found: {vfio_pci_syspath}; Are CONFIG_VFIO "
                    "and CONFIG_VFIO_PCI missing from Kernel conf?")

    if dev.driver == "vfio-pci":
        return;

    v_id = dev.attributes.asstring('vendor').removeprefix('0x')
    d_id = dev.attributes.asstring('device').removeprefix('0x')

    if dev.driver is not None:
        # Unbind from current driver
        try:
            with open(os.path.join(dev.sys_path, "driver", "unbind")) as drv_file:
                drv_file.write(dev.sys_name)
        except Exception as e:
            pytest.fail(f"Could not unbind {dev.sys_name} from its driver: {e}")

        # Remove ID from current driver
        try:
            with open(os.path.join(dev.sys_path, "driver", "remove-id")) as removeid_file:
                removeid_file.write(f"{v_id} {d_id}")
        except Exception as e:
            pytest.fail(f"Could not remove {dev.sys_name} ID from its driver: {e}")

    # Add new ID to the vfio-pci driver
    try:
        with open(os.path.join(vfio_pci_syspath, "new_id"), 'w') as newid_file:
            newid_file.write(f"{v_id} {d_id}")
    except Exception as e:
        pytest.fail(f"Could not add {dev.sys_name} ID to vfio-pci driver: {e}")

    # Bind to vfio-pci driver
    try:
        with open(os.path.join(vfio_pci_syspath, "bind"), 'w') as bind_file:
            bind_file.write(dev.sys_name)
    except Exception as e:
        pytest.fail(f"Could not bind {dev.sys_name} to vfio-pci: {e}")

    #yield # Execute after test

@pytest.fixture
def bind_to_vfio_pci():
    return do_bind_to_vfio_pci
