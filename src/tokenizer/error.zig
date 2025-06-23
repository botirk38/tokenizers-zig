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
    Unimplemented,
};
