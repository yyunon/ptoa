This readme provides information about the simulation environment for the fletcher-aws example. For more details about overall HDK simulation environment and CL bringup in simulation please refer to [RTL_Simulating_CL_Designs](../../../../docs/RTL_Simulating_CL_Designs.md)

# example simulation

The HW/SW co-simulation tests can be run from the [verif/scripts](scripts) directory.
Only XSIM (default) is currently supported.

```
    $ make C_TEST=example (Runs with XSIM by default)
    $ make C_TEST=example QUESTA=1
    
    //To Run in AXI_MEMORY_MODEL mode with AXI memory models instead of DDR.
    
    $ make C_TEST=example AXI_MEMORY_MODEL=1 (Runs with XSIM by default)
    $ make C_TEST=example AXI_MEMORY_MODEL=1 QUESTA=1
    
```

Note that the appropriate simulators must be installed.

# Dump Waves 

In the [verif/scripts](scripts) directory, the file `waves.tcl` specifies what signals to dump during simulations.
These waves can be inspected after simulation has finished.
By default, all signals in the custom logic region and below are added:
```
add_wave -recursive /tb/card/fpga/CL/
```
This can result in long simulation start and run time. If you do not need all the signals, change the file
so that only the signals of interest are added.

For information about how to dump waves with XSIM, please refer to [debugging-custom-logic-using-the-aws-hdk](../../../../docs/RTL_Simulating_CL_Designs.md#debugging-custom-logic-using-the-aws-hdk)

# System Verliog Tests

There are no system verilog tests in [verif/tests](tests).
test_null.sv is a base system verilog file needed for HW/SW co-simulation.

# HW/SW co-simulation Test

The software test with HW/SW co-simulation support [example.c](../software/runtime/example.c) can be found at [software/runtime](../software/runtime). For Information about how HW/SW co-simulation support can be added to a software test please refer to "Code changes to enable HW/SW co-simulation" section in [RTL_Simulating_CL_Designs](../../../../docs/RTL_Simulating_CL_Designs.md)

