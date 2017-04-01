# Lua Benchmarks

Compare the performance of different Lua implementations

## Sample Results

Computer information:

```
Distro: CentOS release 6.8 (Final)
Kernel: 2.6.32-642.13.1.el6.x86_64
CPU:    Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz
```
![](https://raw.githubusercontent.com/gligneul/Lua-Benchmarks/master/results/speedup_luajit.png)
![](https://raw.githubusercontent.com/gligneul/Lua-Benchmarks/master/results/speedup_lua53.png)
![](https://raw.githubusercontent.com/gligneul/Lua-Benchmarks/master/results/speedup_lua5.png)

## Usage

```
usage: lua runbenchmarks.lua [options]
options:
    --nruns <n>      number of times that each test is executed (default = 3)
    --no-supress     don't supress error messages from tests
    --output <name>  name of the benchmark output
    --normalize      normalize the result based on the first binary
    --speedup        compute the speedup based on the first binary
    --no-plot        don't create the plot with gnuplot
    --help           show this message
```

