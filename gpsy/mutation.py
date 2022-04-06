"""Mutation algorithms."""
import random

from deap import gp
from inspect import isclass

def standard_subtree(program, initialization, primitive_set):
    """Standard subtree mutation."""
    index = random.randrange(len(program))
    slice_ = program.searchSubtree(index)
    program[slice_] = initialization(primitive_set=primitive_set)
    return program,

def one_point(program, primitive_set):
    """Wrapper of `gp.mutNodeReplacement`."""
    return gp.mutNodeReplacement(program, primitive_set),

def multi_points(program, num_nodes, primitive_set):
    """Variation of point mutation in which a predetermined, 
    fixed amount of nodes are mutated"""

    if len(program) < 2:
        return program
    
    indices = random.choices(range(1, len(program)), k=num_nodes)

    for index in indices:
        node = program[index]

        if node.arity == 0:  # Terminal
            term = random.choice(primitive_set.terminals[node.ret])
            if isclass(term):
                term = term()
            program[index] = term
        else:  # Primitive
            prims = [p for p in primitive_set.primitives[node.ret] if p.args == node.args]
            program[index] = random.choice(prims)

    return program,

def random_points(program, mutation_probs, primitive_set):
    """Variation of point mutatation in which each node has an
    equal chance of mutating
    mutation_probs is a vector containing probabilities of 
    mutation for each arity"""

    for index in range(0, len(program)-1):
        node = program[index]
        random_val = random.unifrom(0, 1)
        if(random_val < mutation_probs[node.arity]):
            if node.arity == 0:  # Terminal
                term = random.choice(primitive_set.terminals[node.ret])
                if isclass(term):
                    term = term()
                program[index] = term
            else:  # Primitive
                prims = [p for p in primitive_set.primitives[node.ret] if p.args == node.args]
                program[index] = random.choice(prims)
    return program
