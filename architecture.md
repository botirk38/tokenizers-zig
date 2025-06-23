# Tokenizers Zig Port - Architecture Document

## Overview

This document outlines the architecture for porting the HuggingFace Tokenizers library from Rust to Zig with no C dependencies. The original tokenizers library is a high-performance text tokenization library that implements modern tokenization algorithms including BPE, WordPiece, Unigram, and WordLevel.

## Current Architecture Analysis

### Core Pipeline Components

The tokenizers library follows a modular pipeline architecture:

```
Input Text → Normalizer → PreTokenizer → Model → PostProcessor → Output Tokens
                                                       ↓
                                                   Decoder
```

1. **Normalizer**: Handles text normalization (Unicode normalization, case conversion, etc.)
2. **PreTokenizer**: Performs initial text splitting (whitespace, punctuation, etc.)
3. **Model**: Core tokenization algorithm (BPE, WordPiece, Unigram, WordLevel)
4. **PostProcessor**: Adds special tokens, handles padding, truncation
5. **Decoder**: Converts tokens back to original text

### Current Dependencies Requiring Elimination

1. **onig (Oniguruma)** - C regex library (optional, has fancy-regex pure Rust alternative)
2. **esaxx-rs** - Suffix array library with optional C++ backend (has pure Rust fallback)
3. **smp_precompiled** - SentencePiece precompiled normalization (pure Rust implementation)

## Zig Port Architecture

### Core Design Principles

1. **Zero C Dependencies**: All functionality implemented in pure Zig
2. **Memory Safety**: Leverage Zig's compile-time memory safety guarantees
3. **Performance**: Maintain or exceed current performance benchmarks
4. **Modularity**: Preserve the clean modular architecture
5. **Compatibility**: Maintain API compatibility where possible

### Module Structure

```
tokenizers-zig/
├── src/
│   ├── lib.zig                 # Main library entry point
│   ├── tokenizer/
│   │   ├── mod.zig            # Tokenizer implementation
│   │   ├── encoding.zig       # Encoding structures
│   │   ├── added_vocabulary.zig
│   │   └── pattern.zig        # Pattern matching
│   ├── models/
│   │   ├── mod.zig            # Model wrapper
│   │   ├── bpe/
│   │   │   ├── mod.zig        # BPE implementation
│   │   │   ├── trainer.zig    # BPE training
│   │   │   └── model.zig      # BPE model
│   │   ├── wordpiece/
│   │   │   ├── mod.zig        # WordPiece implementation
│   │   │   ├── trainer.zig    # WordPiece training
│   │   │   └── model.zig      # WordPiece model
│   │   ├── unigram/
│   │   │   ├── mod.zig        # Unigram implementation
│   │   │   ├── trainer.zig    # Unigram training
│   │   │   ├── model.zig      # Unigram model
│   │   │   ├── lattice.zig    # Viterbi lattice
│   │   │   └── trie.zig       # Trie data structure
│   │   └── wordlevel/
│   │       ├── mod.zig        # WordLevel implementation
│   │       └── trainer.zig    # WordLevel training
│   ├── normalizers/
│   │   ├── mod.zig            # Normalizer wrapper
│   │   ├── unicode.zig        # Unicode normalization
│   │   ├── bert.zig           # BERT normalization
│   │   ├── byte_level.zig     # Byte-level normalization
│   │   ├── precompiled.zig    # SentencePiece precompiled
│   │   └── replace.zig        # Replace normalizer
│   ├── pre_tokenizers/
│   │   ├── mod.zig            # PreTokenizer wrapper
│   │   ├── whitespace.zig     # Whitespace splitting
│   │   ├── bert.zig           # BERT pre-tokenization
│   │   ├── byte_level.zig     # Byte-level pre-tokenization
│   │   ├── punctuation.zig    # Punctuation handling
│   │   ├── digits.zig         # Digit handling
│   │   ├── metaspace.zig      # Metaspace handling
│   │   └── split.zig          # Generic splitting
│   ├── processors/
│   │   ├── mod.zig            # PostProcessor wrapper
│   │   ├── bert.zig           # BERT post-processing
│   │   ├── roberta.zig        # RoBERTa post-processing
│   │   ├── template.zig       # Template processing
│   │   └── sequence.zig       # Sequence processing
│   ├── decoders/
│   │   ├── mod.zig            # Decoder wrapper
│   │   ├── bpe.zig            # BPE decoder
│   │   ├── wordpiece.zig      # WordPiece decoder
│   │   ├── byte_level.zig     # Byte-level decoder
│   │   └── ctc.zig            # CTC decoder
│   ├── utils/
│   │   ├── mod.zig            # Utility functions
│   │   ├── regex.zig          # Pure Zig regex implementation
│   │   ├── unicode.zig        # Unicode utilities
│   │   ├── suffix_array.zig   # Suffix array implementation
│   │   ├── parallelism.zig    # Parallel processing
│   │   ├── json.zig           # JSON serialization
│   │   ├── cache.zig          # Caching utilities
│   │   ├── padding.zig        # Padding utilities
│   │   └── truncation.zig     # Truncation utilities
│   └── training/
│       ├── mod.zig            # Training utilities
│       ├── progress.zig       # Progress tracking
│       └── vocab_builder.zig  # Vocabulary building
├── tests/
│   ├── models/
│   ├── normalizers/
│   ├── pre_tokenizers/
│   ├── processors/
│   └── integration/
├── benchmarks/
│   ├── encode_bench.zig
│   ├── train_bench.zig
│   └── memory_bench.zig
├── examples/
│   ├── basic_usage.zig
│   ├── training_example.zig
│   └── custom_tokenizer.zig
└── build.zig
```

## Core Data Structures

### Tokenizer

```zig
pub const Tokenizer = struct {
    model: ModelWrapper,
    normalizer: ?NormalizerWrapper,
    pre_tokenizer: ?PreTokenizerWrapper,
    post_processor: ?PostProcessorWrapper,
    decoder: ?DecoderWrapper,
    added_vocabulary: AddedVocabulary,
    truncation: ?TruncationParams,
    padding: ?PaddingParams,
    
    pub fn encode(self: *const Self, input: []const u8, add_special_tokens: bool) !Encoding {
        // Implementation
    }
    
    pub fn decode(self: *const Self, ids: []const u32, skip_special_tokens: bool) ![]u8 {
        // Implementation
    }
    
    pub fn trainFromFiles(self: *Self, trainer: anytype, files: []const []const u8) !void {
        // Implementation
    }
};
```

### Encoding

```zig
pub const Encoding = struct {
    ids: []const u32,
    type_ids: []const u32,
    tokens: []const []const u8,
    words: []const ?u32,
    attention_mask: []const u32,
    special_tokens_mask: []const u32,
    offsets: []const [2]u32,
    
    pub fn merge(self: *Self, other: Encoding, growing_offsets: bool) !void {
        // Implementation
    }
    
    pub fn pad(self: *Self, length: u32, pad_id: u32, pad_type_id: u32, pad_token: []const u8, direction: PaddingDirection) !void {
        // Implementation
    }
    
    pub fn truncate(self: *Self, length: u32, stride: u32, direction: TruncationDirection) !void {
        // Implementation
    }
};
```

### Model Interface

```zig
pub const Model = struct {
    const Self = @This();
    
    tokenizeFn: *const fn (ptr: *anyopaque, sequence: []const u8, allocator: std.mem.Allocator) anyerror![]Token,
    tokenToIdFn: *const fn (ptr: *anyopaque, token: []const u8) ?u32,
    idToTokenFn: *const fn (ptr: *anyopaque, id: u32) ?[]const u8,
    getVocabFn: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) anyerror!std.HashMap([]const u8, u32),
    getVocabSizeFn: *const fn (ptr: *anyopaque) u32,
    saveFn: *const fn (ptr: *anyopaque, folder: []const u8, name: ?[]const u8, allocator: std.mem.Allocator) anyerror![][]const u8,
    getTrainerFn: *const fn (ptr: *anyopaque) anyerror!TrainerWrapper,
    ptr: *anyopaque,
    
    pub fn tokenize(self: Self, sequence: []const u8, allocator: std.mem.Allocator) ![]Token {
        return self.tokenizeFn(self.ptr, sequence, allocator);
    }
    
    pub fn tokenToId(self: Self, token: []const u8) ?u32 {
        return self.tokenToIdFn(self.ptr, token);
    }
    
    pub fn idToToken(self: Self, id: u32) ?[]const u8 {
        return self.idToTokenFn(self.ptr, id);
    }
    
    pub fn getVocab(self: Self, allocator: std.mem.Allocator) !std.HashMap([]const u8, u32) {
        return self.getVocabFn(self.ptr, allocator);
    }
    
    pub fn getVocabSize(self: Self) u32 {
        return self.getVocabSizeFn(self.ptr);
    }
    
    pub fn save(self: Self, folder: []const u8, name: ?[]const u8, allocator: std.mem.Allocator) ![][]const u8 {
        return self.saveFn(self.ptr, folder, name, allocator);
    }
    
    pub fn getTrainer(self: Self) !TrainerWrapper {
        return self.getTrainerFn(self.ptr);
    }
};
```

## Key Implementation Challenges

### 1. Regular Expression Engine

The current implementation uses either Oniguruma (C library) or fancy-regex (Rust). We need a pure Zig implementation:

```zig
pub const Regex = struct {
    pattern: []const u8,
    compiled: CompiledPattern,
    
    pub fn init(pattern: []const u8, allocator: std.mem.Allocator) !Self {
        // Compile regex pattern to internal representation
    }
    
    pub fn findAll(self: *const Self, text: []const u8, allocator: std.mem.Allocator) ![]Match {
        // Find all matches in text
    }
    
    pub fn replace(self: *const Self, text: []const u8, replacement: []const u8, allocator: std.mem.Allocator) ![]u8 {
        // Replace matches with replacement string
    }
};
```

### 2. Suffix Array Implementation

Currently uses esaxx-rs with optional C++ backend. We need pure Zig implementation:

```zig
pub const SuffixArray = struct {
    text: []const u8,
    suffixes: []u32,
    lcp: []u32, // Longest Common Prefix array
    
    pub fn init(text: []const u8, allocator: std.mem.Allocator) !Self {
        // Build suffix array using SA-IS algorithm
    }
    
    pub fn findRepeatedSubstrings(self: *const Self, min_freq: u32, allocator: std.mem.Allocator) ![]SubstringInfo {
        // Find frequent substrings for Unigram training
    }
};
```

### 3. Unicode Normalization

Need comprehensive Unicode support:

```zig
pub const UnicodeNormalizer = struct {
    pub fn normalize(text: []const u8, form: NormalizationForm, allocator: std.mem.Allocator) ![]u8 {
        // Implement Unicode normalization (NFC, NFD, NFKC, NFKD)
    }
    
    pub fn isLowercase(codepoint: u21) bool {
        // Check if codepoint is lowercase
    }
    
    pub fn toLowercase(codepoint: u21) u21 {
        // Convert codepoint to lowercase
    }
    
    pub fn getCategory(codepoint: u21) UnicodeCategory {
        // Get Unicode category
    }
};
```

### 4. Parallel Processing

Implement parallel training and encoding:

```zig
pub const ParallelProcessor = struct {
    thread_pool: std.Thread.Pool,
    
    pub fn init(num_threads: u32, allocator: std.mem.Allocator) !Self {
        // Initialize thread pool
    }
    
    pub fn mapReduce(self: *Self, comptime T: type, items: []const T, mapFn: anytype, reduceFn: anytype) !T {
        // Parallel map-reduce operation
    }
    
    pub fn parallelFor(self: *Self, start: u32, end: u32, func: anytype) !void {
        // Parallel for loop
    }
};
```

### 5. JSON Serialization

For saving/loading tokenizer configurations:

```zig
pub const JsonSerializer = struct {
    pub fn serialize(comptime T: type, value: T, allocator: std.mem.Allocator) ![]u8 {
        // Serialize struct to JSON
    }
    
    pub fn deserialize(comptime T: type, json: []const u8, allocator: std.mem.Allocator) !T {
        // Deserialize JSON to struct
    }
};
```

## Memory Management Strategy

1. **Allocator Pattern**: Use Zig's allocator pattern throughout
2. **Arena Allocators**: Use arena allocators for temporary allocations during training
3. **Reference Counting**: Implement reference counting for shared data structures
4. **Memory Pools**: Use memory pools for frequently allocated objects

## Performance Considerations

1. **SIMD Instructions**: Leverage Zig's SIMD support for vectorized operations
2. **Compile-time Optimizations**: Use comptime for algorithm specialization
3. **Cache-friendly Data Structures**: Design data structures for cache efficiency
4. **Batch Processing**: Implement efficient batch processing for multiple inputs

## Testing Strategy

1. **Unit Tests**: Comprehensive unit tests for each module
2. **Integration Tests**: End-to-end tests with real tokenizer models
3. **Benchmark Tests**: Performance comparison with original Rust implementation
4. **Compatibility Tests**: Ensure output matches original implementation
5. **Property-based Testing**: Use property-based testing for complex algorithms

## Error Handling

Leverage Zig's error handling system:

```zig
pub const TokenizerError = error{
    InvalidInput,
    OutOfMemory,
    FileNotFound,
    InvalidConfiguration,
    TrainingFailed,
    EncodingFailed,
    DecodingFailed,
    InvalidToken,
    VocabularyFull,
};
```

## Compatibility Considerations

1. **JSON Format**: Maintain compatibility with existing tokenizer.json files
2. **Vocabulary Files**: Support existing vocab.txt and merges.txt formats
3. **Model Files**: Support loading existing trained models
4. **API Surface**: Provide similar API to original library where possible

## Future Extensibility

1. **Plugin System**: Design plugin system for custom tokenizers
2. **Custom Models**: Support for user-defined tokenization models
3. **Streaming API**: Support for streaming tokenization of large texts
4. **Hardware Acceleration**: Hooks for GPU acceleration in the future