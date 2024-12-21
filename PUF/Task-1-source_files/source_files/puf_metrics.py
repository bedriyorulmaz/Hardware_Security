import numpy as np
import os
import matplotlib
matplotlib.use('Agg')  # Use non-GUI backend
import matplotlib.pyplot as plt

def read_puf_data(file_paths):
    """Read PUF data from multiple files and structure it."""
    all_data = []
    for file_path in file_paths:
        with open(file_path, 'r') as file:
            lines = file.readlines()
            # Convert each line of hex to binary
            puf_instances = [
                [int(bit) for hex_digit in line.strip() for bit in bin(int(hex_digit, 16))[2:].zfill(4)]
                for line in lines
            ]
            all_data.append(puf_instances)
    return np.array(all_data)  # Shape: (num_files, num_chips, num_bits)

def hamming_distance(bits1, bits2):
    """Calculate Hamming Distance between two binary arrays."""
    return np.sum(bits1 != bits2)

def uniqueness(data):
    """Compute Uniqueness across different PUF instances."""
    num_chips = data.shape[1]
    total_hd = 0
    num_comparisons = 0
    
    for i in range(num_chips):
        for j in range(i + 1, num_chips):
            total_hd += hamming_distance(data[0, i], data[0, j])
            num_comparisons += 1
    
    max_hd = data.shape[2] * num_comparisons
    return (total_hd / max_hd) * 100

def reliability(data):
    """Compute Reliability across multiple readouts for each PUF instance."""
    num_files, num_chips, num_bits = data.shape
    reliability_values = []
    
    for chip_index in range(num_chips):
        reference = data[0, chip_index]
        total_hd = 0
        for file_index in range(1, num_files):
            total_hd += hamming_distance(reference, data[file_index, chip_index])
        
        avg_hd = total_hd / (num_files - 1)
        reliability = 100 - (avg_hd / num_bits) * 100  # Convert to percentage
        reliability_values.append(reliability)

    overall_reliability = np.mean(reliability_values)
    return reliability_values, overall_reliability

def uniformity(data):
    """Compute Uniformity for each PUF instance."""
    uniformity_values = []
    for chip in data[0]:
        hamming_weight = np.sum(chip)
        uniformity_values.append((hamming_weight / len(chip)) * 100)
    return np.mean(uniformity_values)

def bit_aliasing(data):
    """Compute Bit-Aliasing across all PUF instances."""
    num_files, num_chips, num_bits = data.shape
    bit_counts = np.sum(data[0], axis=0)  # Sum bits across chips
    return (np.mean(bit_counts / num_chips)) * 100

# Example Usage
if __name__ == "__main__":
    folder_path = "puf_datas"
    result_path = "result"
    os.makedirs(result_path, exist_ok=True)

    # List of PUF data file paths
    file_paths = [os.path.join(folder_path, f"puf_data_{i}.txt") for i in range(1, 21)]
    
    # Read and process data
    data = read_puf_data(file_paths)  # Shape: (20, num_chips, num_bits)
    
    # Compute metrics
    individual_reliabilities, average_reliability = reliability(data)
    max_reliability, max_chip = max((val, idx + 1) for idx, val in enumerate(individual_reliabilities))
    min_reliability, min_chip = min((val, idx + 1) for idx, val in enumerate(individual_reliabilities))
    uniq = uniqueness(data)
    uniform = uniformity(data)
    bit_alias = bit_aliasing(data)

    # Display results
    print(f"Uniqueness: {uniq:.2f}%")
    print(f"Uniformity: {uniform:.2f}%")
    print(f"Bit-Aliasing: {bit_alias:.2f}%")
    print(f"Average Reliability: {average_reliability:.2f}%")
    print(f"Maximum Reliability: Chip {max_chip} with {max_reliability:.2f}%")
    print(f"Minimum Reliability: Chip {min_chip} with {min_reliability:.2f}%")

    # Save results to a text file
    with open(os.path.join(result_path, "results.txt"), "w") as f:
        f.write(f"Uniqueness: {uniq:.2f}%\n")
        f.write(f"Uniformity: {uniform:.2f}%\n")
        f.write(f"Bit-Aliasing: {bit_alias:.2f}%\n")
        f.write(f"Average Reliability: {average_reliability:.2f}%\n")
        f.write(f"Maximum Reliability: Chip {max_chip} with {max_reliability:.2f}%\n")
        f.write(f"Minimum Reliability: Chip {min_chip} with {min_reliability:.2f}%\n")
        for chip_index, reliability in enumerate(individual_reliabilities, start=1):
            f.write(f"Chip {chip_index}: {reliability:.2f}%\n")

    # Save reliability plot
    plt.figure(figsize=(10, 6))
    plt.plot(range(1, len(individual_reliabilities) + 1), individual_reliabilities, marker='o', linestyle='-', linewidth=2)
    plt.title("Reliability of Each Chip Across Instances", fontsize=14)
    plt.xlabel("Chip Number", fontsize=12)
    plt.ylabel("Reliability (%)", fontsize=12)
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.savefig(os.path.join(result_path, "reliability_plot.png"))
    print("Reliability plot saved to reliability_plot.png")

