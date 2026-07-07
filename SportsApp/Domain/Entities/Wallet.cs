namespace Riyada.Domain.Entities;

public class Wallet
{
    public int Id { get; set; }
    public int OwnerId { get; set; }
    public decimal Balance { get; set; }
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;

    public User? Owner { get; set; }
    public ICollection<WalletTransaction> Transactions { get; set; } = [];
}
