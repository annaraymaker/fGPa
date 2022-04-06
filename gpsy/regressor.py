"""Basic regressor example.
This example file shows how to instantiate the core
`GPRegressor` class given by GPsy (which provides access 
to the relevant `sklearn` functionality) and how to utilize 
the resulting object to solve a symbolic regression problem, 
the dataset of which is provided by the "Penn[sylvania State]
Machine Learning Benchmarks (PMLB)" suite.
"""
from functools import partial
import sys
from time import time

import numpy as np
from pmlb import fetch_data
from sklearn.model_selection import train_test_split

sys.path.insert(1, '../../..')
from gpsy.core import GPRegressor
from gpsy.default import function_sets, hall_of_fame, plot, statistics
import gpsy.evaluation.core as evaluation
import gpsy.evaluation.fitness as fitness
import gpsy.evolution.core as evolution
import gpsy.evolution.initialization as initialization
import gpsy.evolution.selection as selection
import gpsy.evolution.variation.core as variation
import gpsy.evolution.variation.crossover as crossover
import gpsy.evolution.variation.mutation as mutation

########################################################################
# Experiment initialization.
########################################################################

# Reproducible random state.
random_state = np.random.RandomState(0)

# Benchmark dataset.
X, y = fetch_data(
    '649_fri_c0_500_5', return_X_y=True, local_cache_dir='./datasets')

# Split data into training and testing sets: 75% training, 25% testing.
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, random_state=random_state)

# Construct `GPRegressor` regressor (from the `gpsy` package).
regressor = GPRegressor(
    evolution=evolution.standard,   # Overall evolution algorithm.
    evaluation=evaluation.standard, # Program evaluation algorithm.
    # population_size=500,            # Population size.
    population_size=1,
    # n_generations=11,               # Number of generations.
    n_generations=1,
    n_evaluations_threshold=None,   # Evaluation budget.
    fitness=fitness.neg_mse,    # Fitness measure.
    fitness_threshold=(-1e-3),  # Fitness threshold for early termination.
    function_set=function_sets.nicolau_a,   # Function set.
    n_variables=len(X[0]),      # Number of variables.
    n_constants=250,    # Number of fixed ephemeral random constants (ERC).
    constant_generator=np.random.RandomState.uniform,  # ERC generator.
    max_depth=100,      # Maximum program depth.    
    max_size=100,       # Maximum program size.
    initialization=partial(     # Program initializer.
        initialization.ramped_half_and_half, min_depth=0, max_depth=4), 
    selection=partial(          # Selection mechanism.
        selection.tournament, tourn_size=10),
    variation=partial(          # Variation mechanism.
        variation.standard, p_crossover=0, p_mutation=1),  
    crossover=partial(          # Crossover mechanism.
        crossover.standard_subtree, p_terminal=0.1),   
    # mutation=partial(           # Mutation mechanism.
    #     mutation.standard_subtree, 
    #     initialization=partial(
    #         initialization.full, min_depth=0, max_depth=4)),
    # mutation=mutation.one_point,
    # mutation=partial(mutation.multi_points, num_nodes=2),
    mutation=partial(mutation.random_points, mutation_probs=[1, 1, 1]),
    hall_of_fame=hall_of_fame.standard,  # Hall of fame object.
    statistics=statistics.standard,      # Statistics object.
    random_state=random_state,      # Random state.
    verbose=True)                   # Verbosity of output.

# Save current time to be able to measure the duration 
# of the following fitting procedure.
t0 = time()

# Fit regressor to training data.
regressor.fit(X_train, y_train)

# Information about the fitting procedure.
t = time() - t0
print(f'\nDuration of fitting procedure: {t:.2f} seconds '
      f'({t/60:.2f} minutes---or {t/3600:.2f} hours)\n')

# Determine fitness value (i.e., error) on the testing set.
print(f'Fitness for testing set: {regressor.score(X_test, y_test):.6f}\n\n')

# Plot the per-generation results of the GP run.
plot.standard(regressor.logbook_)