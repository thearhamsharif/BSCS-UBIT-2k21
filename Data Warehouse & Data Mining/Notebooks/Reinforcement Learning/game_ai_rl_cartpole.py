# 1. Import Libraries
import warnings

# Suppress the specific pkg_resources deprecation warning from pygame
warnings.filterwarnings(
    "ignore",
    message="pkg_resources is deprecated as an API*",
    category=UserWarning,
)

import numpy as np
np.bool8 = np.bool_  # Fix numpy bool8 attribute error
import gym

# 2. Create the CartPole environment with human rendering mode for visualization
env = gym.make("CartPole-v1", render_mode="human")

episodes = 10  # Number of episodes to run
max_steps = 200  # Max steps per episode

for episode in range(episodes):
    # Reset environment to initial state
    obs = env.reset()

    # Handle new gym reset() returning (obs, info) tuple
    if isinstance(obs, tuple):
        state, _ = obs
    else:
        state = obs

    total_reward = 0

    for step in range(max_steps):
        # No need to call env.render() here, render_mode="human" handles it

        # Select an action randomly from the action space
        action = env.action_space.sample()

        # Take a step in the environment with the selected action
        result = env.step(action)

        # Handle step() output differences between gym versions
        if len(result) == 5:
            next_state, reward, terminated, truncated, info = result
            done = terminated or truncated
        else:
            next_state, reward, done, info = result

        state = next_state
        total_reward += reward

        # Break loop if episode finished
        if done:
            break

    print(f"Episode {episode + 1}: Total Reward = {total_reward}")

# 3. Close environment window
env.close()
