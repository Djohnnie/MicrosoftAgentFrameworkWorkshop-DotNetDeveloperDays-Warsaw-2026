using Microsoft.Agents.AI.Workflows;

[YieldsOutput(typeof(InvestorReview[]))]
public sealed partial class CollectReviewsExecutor() : Executor<InvestorReview>("CollectReviews")
{
    private readonly Dictionary<string, InvestorReview> _reviews = new(StringComparer.Ordinal);

    public override async ValueTask HandleAsync(
        InvestorReview review, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        if (!_reviews.TryAdd(review.Investor, review))
            throw new InvalidOperationException($"Received a duplicate review from {review.Investor}.");

        if (_reviews.Count == 3)
            await context.YieldOutputAsync(
                _reviews.Values.OrderBy(item => item.Investor, StringComparer.Ordinal).ToArray(),
                cancellationToken);
    }
}
