# GPU Type Reference

## Discovering Available GPUs

GPU availability varies by cluster. Always check before presenting options:

```bash
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID/get-addons
```

If you deploy with an unsupported GPU type, the error message lists valid ones:
```
"None of the nodepools support A10G. Valid devices are [T4, A10_4GB, A10_8GB, A10_12GB, A10_24GB, H100_94GB]"
```

## Common GPU Types

| GPU Type | VRAM | Use Case |
|----------|------|----------|
| T4 | 16 GB | Inference, small models |
| A10G | 24 GB | Fine-tuning, medium models |
| A100_40GB | 40 GB | Training, large models |
| A100_80GB | 80 GB | Training, very large models |
| H100_80GB | 80 GB | High-performance training/inference |
| H100_94GB | 94 GB | Maximum performance |

## SDK Usage

```python
from truefoundry import Resources, GPU

resources = Resources(
    cpu_request=2,
    cpu_limit=4,
    memory_request=8000,
    memory_limit=16000,
    devices=[GPU(type="T4", count=1)]
)
```

## Notes

- Not all GPU types are available on every cluster
- Fractional GPUs (MIG) available on some clusters: `A10_4GB`, `A10_8GB`, etc.
- Check cluster addons API for actual availability before recommending
