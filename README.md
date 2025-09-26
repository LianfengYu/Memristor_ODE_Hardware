
## Memristor_ODE_Hardware

## Introduction

This is an Ordinary Differential Equation (ODE) solver based on the Runge-Kutta methods and contains both the regular serial mode and a parallel mode based on Parareal. The code files include software solvers as well as solvers with our 180nm memristor model. This repository contains the software and hardware implementation of our memristor-based ODE solver. The PCB_ctrl folder provides the control code for our custom PCB board and the I²C communication interface with the PC. The RK_verilog folder includes the Verilog implementation of the digital solver used for comparison. The PC_ctrl folder contains the I²C communication code, standard numerical solvers, and the hardware simulation model. In addition, a model folder is provided with an example device model, allowing the supplied scripts to be executed directly. For actual chip testing, we need to use our Verilog code to control the FPGA and communicate with the PC using the I2C protocol to replace the memristor model with the experiment results. 

## Quickstart

Integrators based on software and memristor model can be found in ``./PC_ctrl/integrator``. The parallel integrators can be found in ``./PC_ctrl/parallel``. The Runge-Kutta methods we use can be found in ``./PC_ctrl/ode_method``. Error calculation and step size calculation can be found in ``./PC_ctrl/base``. You can launch ``./PC_ctrl/exp.py``, ``./PC_ctrl/lorenz.py`` and ``./PC_ctrl/threebody.py`` to evaluate the three applications in our experiment. You can launch ``./PC_ctrl/stiff.py`` to evaluate an example of stiff problem. You can launch ``./PC_ctrl/lorenz96.py`` to evaluate an example of Lorenz-96 system.

## Citation

This work is not published yet.
