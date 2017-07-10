A TCL command to be integrated within Synopsys PrimeTime that performs a Dual-Vth post-synthesis optimization.
Such a command reduces leakage power by means of dual-Vth assignment while forcing the percentage of Low-Threshold voltage cells with a given constraint. 
Hard constraint accepts a solution with negative slack while soft constraint will increase the number of lvt cells if the minimum timing requirement is not met.

Synopsis:
dualVth -lvt $percentage$ -constraint [soft|hard]

Overview:
One technique for low-power optimization of digital circuits is to use cells with two different threshold voltage level. Those are, HVT cells that are less leaky but slower and LVT cells that are faster but more leaky. A good mix between the two can provide the best tradeoff between power consumption and performance of the circuit.

The algorithm:
Our approach to the problem is to first swap all cells to HVT. This provides the slowest but less leaky circuit, in terms of power leakage. This version of the circuit is very likely to not meet the timing requirement since is too slow but, if this requirement is satisfied, the algorithm does not optimize and returns immediately since no optimization has to be done.
If this is not the case, first we compute the number of cells that have to be swapped to LVT, then the algorithm starts a while cycle based on the value of the slack of the critical path that has to be negative.
Basic idea is that, in a cycle, we swap to LVT the cells of the critical path, this will increase the slack of the circuit and makes this path not critical anymore. On the next iteration, the critical path is a new one and its cells will be swapped too. This is done in a loop until the slack of the circuit is greater or equal than zero or, if the constraint is set to hard, all the request cells have been swapped. 
With this approach, the timing condition is met but it may happen that the total number of swapped cells is greater than the necessary since cells are swapped in groups (all the cells of the critical paths). 
To solve this problem, we introduce a check on the last path: after every single cell swap, we check the slack and we stop if the timing condition is met, or in the case of hard constraint, all the cells have been swapped. This will prevent to swap more cells than necessary and will guarantee good results without sacrifice the performance in terms of execution time of the command. 

Special thanks to Fabio Pandolfo.
