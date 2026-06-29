# A "Data-Derived" Value May Be Fed by Fixed Constants — Trace Inputs Before Calling It Variable

date: 2026-06-12
scope: frontend / data-viz / reasoning
rule: Before calling a computed UI value variable, trace its inputs — a data-derived-looking scale may be fed by fixed window constants.

## Why
Designing a chart's loading skeleton, I needed to know whether a marker sat at a fixed position. A chart component's scale mapped a `min..max` data domain to the plot width, and the marker's coordinate was computed from that scale. I concluded the marker's position was **data-derived and floating**, so I told the user pinning it would require "fixing the domain" and placed the skeleton's marker near center. The user corrected me: the marker is always at a fixed fraction; the chart is a sliding window. They were right, and the code already said so: the data module fed the domain bounds from **fixed window constants**, not from free data, with a design-intent comment stating the marker's fixed position outright. So the bounds ARE fixed — the scale only *looks* data-derived because I stopped one hop short, at the scale function, instead of tracing what feeds the bounds. I also missed the design-intent comment that stated the invariant.

## How to apply
When a value is computed from a scale, don't classify it as variable/fixed from the formula alone — follow each input to where it originates. Here the inputs were window constants, not free data. Two concrete checks: (1) grep the module that produces the data for window/horizon/range constants before asserting a layout dimension floats; (2) read the design-intent comments in that file first — they often state the invariant that the scale code obscures. When a layout invariant is real, encode it from the same constants so the placeholder and the real chart align to the pixel rather than guessing a fraction. This is the same family as the evidence rule: verify the claim at its source, don't infer it from a downstream symptom.

## Disposition
First occurrence (data chart skeleton, 2026-06-12). User corrected a wrong "it's data-derived" claim; fixed by pinning the skeleton Today to the fixed-window fraction (browser-measured 0% delta vs the real chart). If this recurs — reasoning about a derived UI dimension without tracing its inputs — promote to a standing pre-flight: "trace computed layout values to their source constants + read design-intent comments before claiming variability."
