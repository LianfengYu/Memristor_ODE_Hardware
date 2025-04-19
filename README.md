
## Memristor_ODE_Hardware

## Introduction

This is an Ordinary Differential Equation (ODE) solver based on the Runge-Kutta methods and contains both the regular serial mode and a parallel mode based on Parareal. The code files include software solvers as well as solvers with our 180nm memristor model. For actual chip testing, we need to use our Verilog code to control the FPGA and communicate with the PC using the I2C protocol to replace the memristor model with the experiment results.

## Quickstart

Integrators based on software and memristor model can be found in ``./integrator``. The parallel integrators can be found in ``./parallel``. The Runge-Kutta methods we use can be found in ``./ode_method``. Error calculation and step size calculation can be found in ``./base``. You can launch ``./exp.py``, ``./lorenz.py`` and ``./threebody.py`` to evaluate the three applications in our experiment. You can launch ``./stiff.py`` to evaluate an example of stiff problem.

## Citation

This work is not published yet.
