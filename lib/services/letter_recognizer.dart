import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

/// One prediction from the model: a class label and its probability (0–1).
class Prediction {
  const Prediction(this.label, this.probability);

  final String label;
  final double probability;
}

/// Loads an ONNX model + its labels and turns a drawing into predictions.
///
/// Which model depends on the [LetterCategory] being practiced (consonants
/// and numbers each have their own). Both share the same MobileNetV2
/// preprocessing pipeline, verified empirically for each model:
///   resize to 224x224 (bilinear) -> RGB -> scale pixels to 0–1 ->
///   ImageNet normalization ((x - mean) / std per channel).
/// The drawing board is dark ink on a white background, matching the
/// training data.
class LetterRecognizer {
  LetterRecognizer({required this.modelAsset, required this.labelsAsset});

  final String modelAsset;
  final String labelsAsset;

  static const _inputSize = 224;

  // ImageNet channel statistics used by torchvision's Normalize.
  static const _mean = [0.485, 0.456, 0.406];
  static const _std = [0.229, 0.224, 0.225];

  OrtSession? _session;
  List<String> _labels = const [];

  bool get isReady => _session != null;

  /// Loads the model and labels from assets.
  /// Returns an error message for the UI, or null on success.
  Future<String?> load() async {
    if (isReady) return null;
    try {
      final labelsJson = await rootBundle.loadString(labelsAsset);
      _labels = (jsonDecode(labelsJson) as List).cast<String>();

      final modelBytes = await rootBundle.load(modelAsset);
      OrtEnv.instance.init();
      _session = OrtSession.fromBuffer(
        modelBytes.buffer.asUint8List(),
        OrtSessionOptions(),
      );
      return null;
    } catch (e) {
      return 'Could not load the model. Is ${modelAsset.split('/').last} in '
          'assets/models/? ($e)';
    }
  }

  /// Runs the model on a snapshot of the drawing board.
  Future<List<Prediction>> recognize(ui.Image boardImage) async {
    final session = _session;
    if (session == null) {
      throw StateError('Call load() first');
    }

    final input = await _preprocess(boardImage);
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, _inputSize, _inputSize],
    );

    try {
      final outputs = session.run(
        OrtRunOptions(),
        {session.inputNames.first: inputTensor},
      );
      final raw = (outputs.first?.value as List).first as List;
      final scores = raw.cast<double>();
      for (final o in outputs) {
        o?.release();
      }
      return _topPredictions(_softmax(scores), count: 3);
    } finally {
      inputTensor.release();
    }
  }

  /// ui.Image -> RGB float tensor, ImageNet-normalized, channel-first
  /// (1,3,224,224).
  Future<Float32List> _preprocess(ui.Image boardImage) async {
    // Get raw RGBA pixels out of the Flutter image.
    final byteData =
        await boardImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = byteData!.buffer.asUint8List();

    final decoded = img.Image.fromBytes(
      width: boardImage.width,
      height: boardImage.height,
      bytes: rgba.buffer,
      numChannels: 4,
    );
    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Channel-first layout: all R values, then all G, then all B.
    final floats = Float32List(3 * _inputSize * _inputSize);
    const planeSize = _inputSize * _inputSize;
    var i = 0;
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        floats[i] = (pixel.r / 255.0 - _mean[0]) / _std[0];
        floats[planeSize + i] = (pixel.g / 255.0 - _mean[1]) / _std[1];
        floats[2 * planeSize + i] = (pixel.b / 255.0 - _mean[2]) / _std[2];
        i++;
      }
    }
    return floats;
  }

  List<double> _softmax(List<double> scores) {
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final exps = scores.map((s) => _exp(s - maxScore)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  double _exp(double x) => x < -60 ? 0 : math.exp(x);

  List<Prediction> _topPredictions(List<double> probs, {required int count}) {
    final indexed = List.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));
    return indexed.take(count).map((i) {
      final label = i < _labels.length ? _labels[i] : 'class $i';
      return Prediction(label, probs[i]);
    }).toList();
  }

  void dispose() {
    _session?.release();
    _session = null;
  }
}
