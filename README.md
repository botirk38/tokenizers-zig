# Tokenizers Zig Port

A pure Zig port of the HuggingFace Tokenizers library, with zero C dependencies. This project aims to provide high-performance, memory-safe, and fully compatible tokenization for NLP models, supporting modern algorithms such as BPE, WordPiece, Unigram, and WordLevel.

## Project Goals

- **Zero C Dependencies:** All functionality implemented in Zig.
- **Feature Parity:** Match the original Rust implementation.
- **Performance:** Comparable or better than the Rust version.
- **Memory Safety:** Leverage Zig's safety guarantees.
- **Modular Design:** Clean, extensible architecture.

## Architecture Overview

The tokenization pipeline:

```
Input Text → Normalizer → PreTokenizer → Model → PostProcessor → Output Tokens
                                                   ↓
                                               Decoder
```

Key modules:

- Normalizers (Unicode, BERT, byte-level, etc.)
- PreTokenizers (whitespace, punctuation, regex, etc.)
- Models (BPE, WordPiece, Unigram, WordLevel)
- PostProcessors (special tokens, padding, truncation)
- Decoders (BPE, WordPiece, byte-level, CTC)
- Utilities (regex, unicode, suffix array, JSON, parallelism)

## Roadmap

Development is organized into phases:

1. Foundation & Core Types
2. JSON & Unicode
3. Regex Engine
4. Parallel Processing
5. Normalizers & PreTokenizers
6. Tokenization Models
7. Post-Processing & Decoding
8. Training & Advanced Features
9. Testing, Optimization, Documentation

See [ARCHITECTURE.md](ARCHITECTURE.md) and [ROADMAP.md](ROADMAP.md) for full details.

## License

Apache 2.0 or MIT (to be finalized).
