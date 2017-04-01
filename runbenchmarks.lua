#!/bin/env lua

-- Configuration ---------------------------------------------------------------

-- List of binaries that will be tested
local binaries = {
    { 'lua-5.3.4', 'lua' },
    { 'luajit-2.0.4-interp', 'luajit -joff' },
    { 'luajit-2.0.4', 'luajit' },
}

-- List of tests
local tests_root = './'
local tests = {
    { 'ack', 'ack.lua 3 10' },
    { 'fixpoint-fact', 'fixpoint-fact.lua 3000' },
    { 'heapsort', 'heapsort.lua 10 250000' },
    { 'mandelbrot', 'mandel.lua' },
    { 'juliaset', 'qt.lua' },
    { 'queen', 'queen.lua 12' },
    { 'sieve', 'sieve.lua 5000' }, -- Sieve of Eratosthenes
    { 'binary', 'binary-trees.lua 15' },
    { 'n-body', 'n-body.lua 1000000' },
    { 'fannkuch', 'fannkuch-redux.lua 10' },
    { 'fasta', 'fasta.lua 2500000' },
    { 'k-nucleotide', 'k-nucleotide.lua < fasta1000000.txt' },
    --{ 'regex-dna', 'regex-dna.lua < fasta1000000.txt' },
    { 'spectral-norm', 'spectral-norm.lua 1000' },
}

-- Command line arguments ------------------------------------------------------

local nruns = 3
local supress_errors = true 
local basename = 'results'
local normalize = false
local speedup = false
local plot = true

local usage = [[
usage: lua ]] .. arg[0] .. [[ [options]
options:
    --nruns <n>      number of times that each test is executed (default = 3)
    --no-supress     don't supress error messages from tests
    --output <name>  name of the benchmark output
    --normalize      normalize the result based on the first binary
    --speedup        compute the speedup based on the first binary
    --no-plot        don't create the plot with gnuplot
    --help           show this message
]]

local function parse_args()
    local function parse_error(msg)
        print('Error: ' .. msg .. '\n' .. usage)
        os.exit(1)
    end
    local function get_next_arg(i)
        if i + 1 > #arg then
            parse_error(arg[i] .. ' requires a value')
        end
        local v = arg[i + 1]
        arg[i + 1] = nil
        return v
    end
    for i = 1, #arg do
        if not arg[i] then goto continue end
        if arg[i] == '--nruns' then
            nruns = tonumber(get_next_arg(i))
            if not nruns or nruns < 1 then
                parse_error('nruns should be a number greater than 1')
            end
        elseif arg[i] == '--no-supress' then
            supress_errors = false
        elseif arg[i] == '--output' then
            basename = get_next_arg(i)
        elseif arg[i] == '--normalize' then
            normalize = true
        elseif arg[i] == '--speedup' then
            speedup = true
        elseif arg[i] == '--no-plot' then
            plot = false
        elseif arg[i] == '--help' then
            print(usage)
            os.exit()
        else
            parse_error('invalid argument: ' .. arg[i])
        end
        ::continue::
    end
end

-- Implementation --------------------------------------------------------------

-- Run the command a single time and returns the time elapsed
local function measure(cmd)
    local time_cmd = '{ TIMEFORMAT=\'%3R\'; time ' ..  cmd ..
            ' > /dev/null; } 2>&1'
    local handle = io.popen(time_cmd)
    local result = handle:read("*a")
    local time_elapsed = tonumber(result)
    handle:close()
    if not time_elapsed then
        error('Invalid output for "' .. cmd .. '":\n' .. result)
    end
    return time_elapsed
end

-- Run the command $nruns and return the fastest time
local function benchmark(cmd)
    local min = 999
    io.write('running "' .. cmd .. '"... ')
    for _ = 1, nruns do
        local time = measure(cmd)
        min = math.min(min, time)
    end
    io.write('done\n')
    return min
end

-- Create a matrix with n rows
local function create_matrix(n)
    local m = {}
    for i = 1, n do
        m[i] = {}
    end
    return m
end

-- Measure the time for each binary and test
-- Return a matrix with the result (test x binary)
local function run_all()
    local results = create_matrix(#tests)
    for i, test in ipairs(tests) do
        local test_path = tests_root .. test[2]
        for j, binary in ipairs(binaries) do
            local cmd = binary[2] .. ' ' .. test_path
            local ok, msg = pcall(function()
                results[i][j] = benchmark(cmd)
            end)
            if not ok and not supress_errors then
                io.write('error:\n' .. msg .. '\n---\n')
            end
        end
    end
    return results 
end

-- Perform an operation for each value in the matrix
local function process_results(results, f)
    for _, line in ipairs(results) do
        local base = line[1]
        for i = 1, #binaries do
            line[i] = f(line[i], base)
        end
    end
end

-- Print info about the host computer
local function computer_info()
    os.execute([[
echo "Distro: "`cat /etc/*-release | head -1`
echo "Kernel: "`uname -r`
echo "CPU:    "`cat /proc/cpuinfo | grep 'model name' | tail -1 | \
                sed 's/model name.*:.//'`]])
end

-- Creates and saves the gnuplot data file
local function create_data_file(results)
    local data = 'test\t'
    for _, binary in ipairs(binaries) do
        data = data .. binary[1] .. '\t'
    end
    data = data .. '\n'
    for i, test in ipairs(tests) do
        data = data .. test[1] .. '\t'
        for j, _ in ipairs(binaries) do
            data = data .. results[i][j] .. '\t' 
        end
        data = data .. '\n'
    end
    io.open(basename .. '.txt', 'w'):write(data):close()
end

-- Generates the output image with gnuplot
local function generate_image()
    local ylabel
    if normalize then
        ylabel = 'Normalized time'
    elseif speedup then
        ylabel = 'Speedup'
    else
        ylabel = 'Elapsed time'
    end
    os.execute('gnuplot -e "datafile=\'' .. basename .. '.txt\'" ' ..
               '-e "outfile=\'' .. basename .. '.png\'" ' ..
               '-e "ylabel=\'' .. ylabel .. '\'" ' ..
               '-e "nbinaries=' .. #binaries .. '" plot.gpi')
end

local function setup()
    os.execute('luajit ' .. tests_root .. 'fasta.lua 1000000 > fasta1000000.txt')
end

local function teardown()
    os.execute('rm fasta1000000.txt')
end

local function main()
    parse_args()
    computer_info()
    setup()
    local results = run_all()
    teardown()
    local function f(v, base)
        if not v then
            return 0
        elseif not base then
            return v
        elseif speedup then
            return base / v
        elseif normalize then
            return v / base
        else
            return v
        end
    end
    process_results(results, f)
    create_data_file(results)
    if plot then generate_image() end
    print('final done')
end

main()

