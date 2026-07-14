# ONNX model goes here

Place your trained Chakma letter recognition model in this folder, named:

    chakma_model.onnx

When we wire up inference (next step), the app will load it from
`assets/models/chakma_model.onnx` using the `onnxruntime` Flutter package.

Things we'll need to know about the model before wiring it up:

1. Input shape — e.g. [1, 1, 28, 28] (batch, channels, height, width)?
2. Input color/scale — grayscale? Pixel values 0–1 or 0–255? Normalized (mean/std)?
3. Ink polarity — white letter on black background, or black on white?
4. Output — how many classes, and the index → letter mapping (label order)?
