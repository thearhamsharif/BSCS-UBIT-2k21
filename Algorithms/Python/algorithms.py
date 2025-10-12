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
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quick_sort(left) + middle + quick_sort(right)


def merge_sort(arr):
    if len(arr) > 1:
        mid = len(arr) // 2
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


def heap_sort(arr):
    def heapify(arr, n, i):
        largest = i
        l = 2 * i + 1
        r = 2 * i + 2

        if l < n and arr[l] > arr[largest]:
            largest = l

        if r < n and arr[r] > arr[largest]:
            largest = r

        if largest != i:
            arr[i], arr[largest] = arr[largest], arr[i]
            heapify(arr, n, largest)

    n = len(arr)
    for i in range(n // 2 - 1, -1, -1):
        heapify(arr, n, i)

    for i in range(n-1, 0, -1):
        arr[i], arr[0] = arr[0], arr[i]
        heapify(arr, i, 0)
    return arr


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

    if spam_score > 2:  # Threshold can be adjusted
        return "Spam"
    else:
        return "Not Spam"


def fractional_knapsack(weights, values, capacity):
    index = list(range(len(values)))
    ratio = [v/w for v, w in zip(values, weights)]
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
    import heapq
    queue = []
    heapq.heappush(queue, (0, start))
    distances = {node: float('inf') for node in graph}
    distances[start] = 0

    while queue:
        current_distance, current_node = heapq.heappop(queue)

        if current_distance > distances[current_node]:
            continue

        for neighbor, weight in graph[current_node].items():
            distance = current_distance + weight

            if distance < distances[neighbor]:
                distances[neighbor] = distance
                heapq.heappush(queue, (distance, neighbor))

    return distances


def kruskal(graph):
    parent = {}
    rank = {}

    def find(node):
        if parent[node] != node:
            parent[node] = find(parent[node])
        return parent[node]

    def union(node1, node2):
        root1 = find(node1)
        root2 = find(node2)

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
    import heapq
    mst = []
    visited = set([start])
    edges = [(weight, start, to) for to, weight in graph[start].items()]
    heapq.heapify(edges)

    while edges:
        weight, frm, to = heapq.heappop(edges)
        if to not in visited:
            visited.add(to)
            mst.append((frm, to, weight))

            for to_next, weight in graph[to].items():
                if to_next not in visited:
                    heapq.heappush(edges, (weight, to, to_next))

    return mst


def huffman_coding(symbols, frequencies):
    import heapq
    heap = [[weight, [symbol, ""]]
            for symbol, weight in zip(symbols, frequencies)]
    heapq.heapify(heap)

    while len(heap) > 1:
        lo = heapq.heappop(heap)
        hi = heapq.heappop(heap)
        for pair in lo[1:]:
            pair[1] = '0' + pair[1]
        for pair in hi[1:]:
            pair[1] = '1' + pair[1]
        heapq.heappush(heap, [lo[0] + hi[0]] + lo[1:] + hi[1:])

    return sorted(heapq.heappop(heap)[1:], key=lambda p: (len(p[-1]), p))


def bfs(graph, start):
    from collections import deque
    visited = set()
    queue = deque([start])
    order = []

    while queue:
        vertex = queue.popleft()
        if vertex not in visited:
            visited.add(vertex)
            order.append(vertex)
            queue.extend(
                neighbor for neighbor in graph[vertex] if neighbor not in visited)

    return order


def dfs(graph, start, visited=None):
    if visited is None:
        visited = set()
    visited.add(start)
    order = [start]

    for neighbor in graph[start]:
        if neighbor not in visited:
            order.extend(dfs(graph, neighbor, visited))

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
    sorted_arr = sorted(arr)
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
