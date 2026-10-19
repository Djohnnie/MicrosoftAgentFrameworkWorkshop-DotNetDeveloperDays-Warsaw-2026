using Microsoft.Extensions.VectorData;

public sealed class DocumentChunk
{
    [VectorStoreKey]
    public required string Id { get; set; }

    [VectorStoreData]
    public required string Source { get; set; }

    [VectorStoreData]
    public required string Text { get; set; }

    [VectorStoreVector(1536, DistanceFunction = DistanceFunction.CosineSimilarity)]
    public ReadOnlyMemory<float> Embedding { get; set; }
}
