# The Succinct Compiler
This is the Succinct language compiler.

### Example code
```python
CONSTANTE = 1

func fibonacci(int n) int:
  if n == 0:
    0
  elif n == 1:
    1
  else:
    fibonacci(n - 1) + fibonacci(n - 2)

print(fibonacci(10))
```
