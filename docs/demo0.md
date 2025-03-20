# Demo 0

## Note

* Running [debian script](demo0_debian.sh) should give you similar result. Your
  milage may vary depending on the versions of the deps.

* The [debian script](demo0_debian.sh) assumes that there is a kernel built
  under ${HOME}/src/iommu/biommutests. Make sure you provide a kernel built
  with vfio activated, for the tests to give you similar results.

## Steps

See the implementation of these steps in the [debian script](demo0_debian.sh)

1. Install Deps and Build Qemu:
2. Download and Configure Ubuntu Cloud Image:
3. Run Qemu
4. Install Deps on VM
5. Build libvfn
6. Build iommutests
7. Run iommutetss

## Ouptput

This is the result of running the [debian script](demo_debian.sh)

```
    ~/iommutests/builddir ~
    ============================= test session starts ==============================
    platform linux -- Python 3.12.3, pytest-7.4.4, pluggy-1.4.0
    rootdir: /home/vmuser/iommutests/builddir
    collected 2 items

    tests/demo0/test_dma_01.py .F                                            [100%]

    =================================== FAILURES ===================================
    ___________________ test_dma_01[echo_param1-pci_dev_enumer0] ___________________

    capsys = <_pytest.capture.CaptureFixture object at 0x7fe32dc4e930>
    setup_and_teardown = <pyudev.core.Enumerator object at 0x7fe32dbdce60>
    exec_cmd = <function exec_cmd.<locals>._factory at 0x7fe32da41b20>
    echo_param = ['--fail']

        @pytest.mark.parametrize("pci_dev_enumer",
                [{"device": "0x11e9", "vendor": "0x1234"}],
                indirect = True)
        @pytest.mark.parametrize("echo_param",
                [[], ["--fail"]], indirect = True)
        def test_dma_01(capsys, setup_and_teardown, exec_cmd, echo_param):
            pci_enumer = setup_and_teardown
            for pci_dev in pci_enumer:
                cmd = [test_exec, "--device", pci_dev.sys_name] + echo_param
    >           assert exec_cmd(cmd) == True
    E           AssertionError: assert False == True
    E            +  where False = <function exec_cmd.<locals>._factory at 0x7fe32da41b20>(['/home/vmuser/iommutests/builddir/tests/demo0/dma_01', '--device', '0000:00:03.0', '--fail'])

    tests/demo0/test_dma_01.py:32: AssertionError
    ----------------------------- Captured stdout call -----------------------------
    {'args': ['/home/vmuser/iommutests/builddir/tests/demo0/dma_01',
              '--device',
              '0000:00:03.0',
              '--fail'],
     'returncode': 1,
     'stderr': b'D init_page_size (src/support/mem.c:44): support/mem: pagesize i'
               b's 4096 (shift 12)\nD measure_ticks_freq (src/support/ticks.c:39):'
               b' support/ticks: measuring tick frequency\nD init_ticks_freq (src/'
               b'support/ticks.c:87): support/ticks: tick frequency is ~380000000'
               b'0 Hz\n',
     'stdout': b''}
    ========================= 1 failed, 1 passed in 0.22s ==========================

```

## Recording

![](./demo0_debian.gif)


