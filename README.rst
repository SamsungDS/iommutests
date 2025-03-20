===========
IOMMU tests
===========

IOMMU tests provides the infrastructure to test the software as well as
hardware components of Direct Memory Access interactions orchestrated by an
IOMMU (Input Output Memory Management Unit). It provides the following
functionalities:

1. Libraries and common reusable user space code that enables the creation of
   IOMMU tests.
2. A pytest orchestration infrastructure that is able to execute tests
   depending on the system that is being run.

Build
=====

To build the tests compatible with your the system configuration used for
building.

.. code-block:: shell

        meson setup builddir
        meson compile -C builddir

Running
=======

Execute all the tests that are available in the system configuration used for
running. Availability depends on installed hardware and software. `Pytest's
arguments`_ are available to customize test runs.

.. _Pytest's arguments: https://docs.pytest.org/en/6.2.x/usage.html

.. code-block:: shell

        pytest builddir

Contributing
============

See `CONTRIBUTING <CONTRIBUTING>`_.


Demo 0
======

If you are curious how iommutests work, the 0 demo describes (with a script)
how that would look like. See `demo0 <docs/demo0.md>`_
