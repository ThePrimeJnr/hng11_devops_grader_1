numbers = [5, 2, 1, 7]
permutations = []

for i in numbers:
    for j in numbers:
        for k in numbers:
            for l in numbers:
                permutations.append(f"{i}{j}{k}{l}")

# Print all permutations separated by a comma
print(','.join(permutations))

