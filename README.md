# integrate

OmniBenchmark integration/batch-correction module. Currently implements Harmony (`harmony-r`).

## Setup

```bash
pixi install
pixi run check
```

## Usage

```bash
Rscript harmony.R \
  --output_dir out/ \
  --name sc-mix_filter-type_manual_... \
  --pcas.tsv path/to/sc-mix_pcas.tsv \
  --rawdata.h5ad path/to/sc-mix.h5ad \
  --batch_variable Sample \
  --theta 2
```

## Output

TSV file `{output_dir}/{name}_hmny_corrected.tsv` with the same layout as the PCA input (this should be fixed)

```
cell_id    hmny1    hmny2   ...  hmny50
AAACCT...  0.312   -1.045   ...  0.008
```

## Entrypoints

| Entrypoint  | Script      | Method  |
|-------------|-------------|---------|
| `harmony-r` | harmony.R   | Harmony |
