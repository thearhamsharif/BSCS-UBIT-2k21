# Custom queue functions for BFS
def enqueue(queue, item):
    queue.append(item)


def dequeue(queue):
    return queue.pop(0)


def is_empty(queue):
    return len(queue) == 0

# Custom priority queue functions for Dijkstra/Prim (min-heap behavior)


def pq_insert(pq, item):
    pq.append(item)
    pq.sort()


def pq_extract_min(pq):
    return pq.pop(0)


def pq_is_empty(pq):
    return len(pq) == 0

# Sorting Algorithms


def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n-i-1):
            if arr[j] > arr[j+1]:
                arr[j], arr[j+1] = arr[j+1], arr[j]
    return arr


def quick_sort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr)//2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quick_sort(left) + middle + quick_sort(right)


def merge_sort(arr):
    if len(arr) > 1:
        mid = len(arr)//2
        L = arr[:mid]
        R = arr[mid:]
        merge_sort(L)
        merge_sort(R)
        i = j = k = 0
        while i < len(L) and j < len(R):
            if L[i] < R[j]:
                arr[k] = L[i]
                i += 1
            else:
                arr[k] = R[j]
                j += 1
            k += 1
        while i < len(L):
            arr[k] = L[i]
            i += 1
            k += 1
        while j < len(R):
            arr[k] = R[j]
            j += 1
            k += 1
    return arr


def insertion_sort(arr):
    for i in range(1, len(arr)):
        key = arr[i]
        j = i-1
        while j >= 0 and key < arr[j]:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key
    return arr


def selection_sort(arr):
    for i in range(len(arr)):
        min_idx = i
        for j in range(i+1, len(arr)):
            if arr[j] < arr[min_idx]:
                min_idx = j
        arr[i], arr[min_idx] = arr[min_idx], arr[i]
    return arr


def heapify(arr, n, i):
    largest = i
    l = 2*i + 1
    r = 2*i + 2
    if l < n and arr[l] > arr[largest]:
        largest = l
    if r < n and arr[r] > arr[largest]:
        largest = r
    if largest != i:
        arr[i], arr[largest] = arr[largest], arr[i]
        heapify(arr, n, largest)


def heap_sort(arr):
    n = len(arr)
    for i in range(n//2 - 1, -1, -1):
        heapify(arr, n, i)
    for i in range(n-1, 0, -1):
        arr[i], arr[0] = arr[0], arr[i]
        heapify(arr, i, 0)
    return arr

# Searching Algorithms


def linear_search(arr, target):
    for i in range(len(arr)):
        if arr[i] == target:
            return i
    return -1


def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1

# Spam Detection Algorithms


def spam_filter_using_naive_bayes(email, spam_words, ham_words):
    email_words = email.lower().split()
    spam_count = sum(1 for word in email_words if word in spam_words)
    ham_count = sum(1 for word in email_words if word in ham_words)
    if spam_count > ham_count:
        return "Spam"
    else:
        return "Not Spam"


def spam_filter_using_svm(email, spam_keywords):
    email_words = email.lower().split()
    spam_score = sum(1 for word in email_words if word in spam_keywords)
    if spam_score > 2:
        return "Spam"
    else:
        return "Not Spam"

# Greedy Algorithms


def fractional_knapsack(weights, values, capacity):
    n = len(values)
    index = list(range(n))
    ratio = [values[i]/weights[i] for i in range(n)]
    index.sort(key=lambda i: ratio[i], reverse=True)
    max_value = 0
    for i in index:
        if weights[i] <= capacity:
            capacity -= weights[i]
            max_value += values[i]
        else:
            max_value += values[i] * (capacity / weights[i])
            break
    return max_value


def dijkstra(graph, start):
    distances = {node: float('inf') for node in graph}
    distances[start] = 0
    pq = []
    pq_insert(pq, (0, start))
    visited = set()
    while not pq_is_empty(pq):
        current_distance, current_node = pq_extract_min(pq)
        if current_node in visited:
            continue
        visited.add(current_node)
        for neighbor in graph[current_node]:
            distance = current_distance + graph[current_node][neighbor]
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                pq_insert(pq, (distance, neighbor))
    return distances


def kruskal(graph):
    parent = {}
    rank = {}

    def find(node):
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    def union(u, v):
        root1 = find(u)
        root2 = find(v)
        if root1 != root2:
            if rank[root1] > rank[root2]:
                parent[root2] = root1
            else:
                parent[root1] = root2
                if rank[root1] == rank[root2]:
                    rank[root2] += 1
    for node in graph['vertices']:
        parent[node] = node
        rank[node] = 0
    mst = []
    edges = sorted(graph['edges'], key=lambda x: x[2])
    for edge in edges:
        u, v, weight = edge
        if find(u) != find(v):
            union(u, v)
            mst.append(edge)
    return mst


def prim(graph, start):
    mst = []
    visited = set([start])
    nodes = list(graph.keys())
    pq = []
    for v, w in graph[start].items():
        pq_insert(pq, (w, start, v))
    while len(visited) < len(nodes):
        if pq_is_empty(pq):
            break
        w, u, v = pq_extract_min(pq)
        if v not in visited:
            visited.add(v)
            mst.append((u, v, w))
            for to_next, weight in graph[v].items():
                if to_next not in visited:
                    pq_insert(pq, (weight, v, to_next))
    return mst


def huffman_coding(symbols, frequencies):
    nodes = [[freq, [sym, ""]] for sym, freq in zip(symbols, frequencies)]
    while len(nodes) > 1:
        nodes = sorted(nodes, key=lambda x: x[0])
        lo = nodes.pop(0)
        hi = nodes.pop(0)
        for pair in lo[1:]:
            pair[1] = '0' + pair[1]
        for pair in hi[1:]:
            pair[1] = '1' + pair[1]
        nodes.append([lo[0]+hi[0]] + lo[1:] + hi[1:])
    return sorted(nodes[0][1:], key=lambda p: (len(p[-1]), p))

# Graph Traversal Algorithms


def bfs(graph, start):
    visited = set()
    queue = []
    enqueue(queue, start)
    order = []
    while not is_empty(queue):
        vertex = dequeue(queue)
        if vertex not in visited:
            visited.add(vertex)
            order.append(vertex)
            for neighbor in graph[vertex]:
                if neighbor not in visited:
                    enqueue(queue, neighbor)
    return order


def dfs(graph, start, visited=None, order=None):
    if visited is None:
        visited = set()
    if order is None:
        order = []
    visited.add(start)
    order.append(start)
    for neighbor in graph[start]:
        if neighbor not in visited:
            dfs(graph, neighbor, visited, order)
    return order


# Run function examples
if __name__ == "__main__":
    arr = [64, 34, 25, 12, 22, 11, 90]
    print("Bubble Sort:", bubble_sort(arr.copy()))
    print("Quick Sort:", quick_sort(arr.copy()))
    print("Merge Sort:", merge_sort(arr.copy()))
    print("Insertion Sort:", insertion_sort(arr.copy()))
    print("Selection Sort:", selection_sort(arr.copy()))
    print("Heap Sort:", heap_sort(arr.copy()))

    target = 22
    print("Linear Search:", linear_search(arr, target))
    sorted_arr = heap_sort(arr.copy())
    print("Binary Search:", binary_search(sorted_arr, target))

    spam_words = ["buy", "cheap", "discount"]
    ham_words = ["meeting", "project", "schedule"]
    email1 = "Get a cheap discount now"
    email2 = "Let's schedule a project meeting"
    print("Spam Filter (Naive Bayes) Email1:",
          spam_filter_using_naive_bayes(email1, spam_words, ham_words))
    print("Spam Filter (Naive Bayes) Email2:",
          spam_filter_using_naive_bayes(email2, spam_words, ham_words))

    spam_keywords = ["buy", "cheap", "discount"]
    print("Spam Filter (SVM) Email1:",
          spam_filter_using_svm(email1, spam_keywords))
    print("Spam Filter (SVM) Email2:",
          spam_filter_using_svm(email2, spam_keywords))

    weights = [10, 20, 30]
    values = [60, 100, 120]
    capacity = 50
    print("Fractional Knapsack:", fractional_knapsack(weights, values, capacity))

    graph_dijkstra = {
        'A': {'B': 1, 'C': 4},
        'B': {'A': 1, 'C': 2, 'D': 5},
        'C': {'A': 4, 'B': 2, 'D': 1},
        'D': {'B': 5, 'C': 1}
    }
    print("Dijkstra's Algorithm:", dijkstra(graph_dijkstra, 'A'))

    graph_kruskal = {
        'vertices': ['A', 'B', 'C', 'D'],
        'edges': [
            ('A', 'B', 1),
            ('A', 'C', 4),
            ('B', 'C', 2),
            ('B', 'D', 5),
            ('C', 'D', 1)
        ]
    }
    print("Kruskal's Algorithm:", kruskal(graph_kruskal))

    graph_prim = {
        'A': {'B': 1, 'C': 4},
        'B': {'A': 1, 'C': 2, 'D': 5},
        'C': {'A': 4, 'B': 2, 'D': 1},
        'D': {'B': 5, 'C': 1}
    }
    print("Prim's Algorithm:", prim(graph_prim, 'A'))

    symbols = ['a', 'b', 'c', 'd']
    frequencies = [5, 9, 12, 13]
    print("Huffman Coding:", huffman_coding(symbols, frequencies))

    graph_bfs = {
        'A': ['B', 'C'],
        'B': ['A', 'D', 'E'],
        'C': ['A', 'F'],
        'D': ['B'],
        'E': ['B', 'F'],
        'F': ['C', 'E']
    }
    print("BFS:", bfs(graph_bfs, 'A'))
    print("DFS:", dfs(graph_bfs, 'A'))

# End of file
