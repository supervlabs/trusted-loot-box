import random
from datetime import datetime, timedelta


def get_fake_rewards(since: str, n: int = 10, seed: int | None = None) -> list[tuple]:
    random.seed(seed)

    reward_grades = ("Common", "Uncommon", "Rare", "Epic", "Legendary")
    reward_probabilities = (0.6, 0.25, 0.1, 0.04, 0.01)
    assert sum(reward_probabilities) == 1.0

    rewards = random.choices(reward_grades, reward_probabilities, k=n)

    result = []
    current_datetime = datetime.strptime(since, "%Y-%m-%dT%H:%M:%SZ")

    for r in rewards:
        counter = [0, 0, 0, 0, 0]
        idx_r = reward_grades.index(r)
        counter[idx_r] = 1

        current_datetime += timedelta(seconds=random.randint(0, 60))
        datetime_str = current_datetime.isoformat() + "Z"

        row = (datetime_str,) + tuple(counter)
        result.append(row)

    return result
