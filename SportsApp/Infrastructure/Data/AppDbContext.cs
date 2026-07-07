using Microsoft.EntityFrameworkCore;
using Riyada.Domain.Entities;

namespace Riyada.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Field> Fields => Set<Field>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<OwnerFeeInvoice> OwnerFeeInvoices => Set<OwnerFeeInvoice>();
    public DbSet<OwnerFeeInvoiceItem> OwnerFeeInvoiceItems => Set<OwnerFeeInvoiceItem>();
    public DbSet<PlatformPayment> PlatformPayments => Set<PlatformPayment>();
    public DbSet<BookingPayment> BookingPayments => Set<BookingPayment>();
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<WalletTransaction> WalletTransactions => Set<WalletTransaction>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<SecurityLog> SecurityLogs => Set<SecurityLog>();
    public DbSet<PushNotificationLog> PushNotificationLogs => Set<PushNotificationLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(u => u.Email).IsUnique();
            entity.Property(u => u.Name).HasMaxLength(200);
            entity.Property(u => u.Email).HasMaxLength(256);
            entity.Property(u => u.Role).HasMaxLength(20);
            entity.Property(u => u.AccountStatus).HasMaxLength(20);
        });

        modelBuilder.Entity<Field>(entity =>
        {
            // Legacy SQLite table name from MVP
            entity.ToTable("Stadiums");
            entity.Property(f => f.Name).HasMaxLength(200);
            entity.Property(f => f.Address).HasMaxLength(500);
            entity.HasOne(f => f.Owner)
                .WithMany(u => u.OwnedFields)
                .HasForeignKey(f => f.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Booking>(entity =>
        {
            // DB column remains StadiumId; domain uses FieldId
            entity.Property(b => b.FieldId).HasColumnName("StadiumId");
            entity.Property(b => b.Status).HasMaxLength(20);
            entity.HasOne(b => b.User)
                .WithMany(u => u.Bookings)
                .HasForeignKey(b => b.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(b => b.Field)
                .WithMany(f => f.Bookings)
                .HasForeignKey(b => b.FieldId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(b => new { b.FieldId, b.StartTime });
            entity.HasIndex(b => new { b.FieldId, b.Status });
            entity.HasIndex(b => new { b.UserId, b.Status });
            entity.HasIndex(b => new { b.UserId, b.CancelledAt });
            entity.Property(b => b.PaymentMethod).HasMaxLength(20);
        });

        modelBuilder.Entity<SecurityLog>(entity =>
        {
            entity.Property(s => s.EventType).HasMaxLength(40);
            entity.Property(s => s.Reason).HasMaxLength(200);
            entity.Property(s => s.Details).HasMaxLength(1000);
            entity.HasOne(s => s.User)
                .WithMany()
                .HasForeignKey(s => s.UserId)
                .OnDelete(DeleteBehavior.SetNull);
            entity.HasIndex(s => new { s.UserId, s.CreatedAt });
            entity.HasIndex(s => s.EventType);
        });

        modelBuilder.Entity<PushNotificationLog>(entity =>
        {
            entity.Property(l => l.DeviceTokenPreview).HasMaxLength(32);
            entity.Property(l => l.Title).HasMaxLength(200);
            entity.Property(l => l.Body).HasMaxLength(500);
            entity.Property(l => l.EventType).HasMaxLength(40);
            entity.Property(l => l.Status).HasMaxLength(20);
            entity.Property(l => l.ProviderMessageId).HasMaxLength(128);
            entity.Property(l => l.Error).HasMaxLength(500);
            entity.HasOne(l => l.User)
                .WithMany()
                .HasForeignKey(l => l.UserId)
                .OnDelete(DeleteBehavior.SetNull);
            entity.HasIndex(l => new { l.UserId, l.CreatedAt });
            entity.HasIndex(l => l.Status);
        });

        modelBuilder.Entity<Wallet>(entity =>
        {
            entity.HasOne(w => w.Owner)
                .WithMany()
                .HasForeignKey(w => w.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(w => w.OwnerId).IsUnique();
        });

        modelBuilder.Entity<WalletTransaction>(entity =>
        {
            entity.Property(t => t.Type).HasMaxLength(40);
            entity.Property(t => t.Description).HasMaxLength(500);
            entity.Property(t => t.AdminNote).HasMaxLength(500);
            entity.HasOne(t => t.Wallet)
                .WithMany(w => w.Transactions)
                .HasForeignKey(t => t.WalletId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(t => t.Booking)
                .WithMany()
                .HasForeignKey(t => t.BookingId)
                .OnDelete(DeleteBehavior.SetNull);
            entity.HasIndex(t => new { t.WalletId, t.CreatedAt });
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(n => new { n.UserId, n.CreatedAt });
            entity.HasIndex(n => new { n.UserId, n.IsRead });
        });

        modelBuilder.Entity<DeviceToken>(entity =>
        {
            entity.Property(t => t.Token).HasMaxLength(512);
            entity.Property(t => t.Platform).HasMaxLength(20);
            entity.HasOne(t => t.User)
                .WithMany(u => u.DeviceTokens)
                .HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(t => t.Token).IsUnique();
            entity.HasIndex(t => t.UserId);
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.Property(r => r.Comment).HasMaxLength(1000);
            entity.HasOne(r => r.User)
                .WithMany(u => u.Reviews)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(r => r.Field)
                .WithMany(f => f.Reviews)
                .HasForeignKey(r => r.FieldId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(r => new { r.FieldId, r.UserId }).IsUnique();
        });

        modelBuilder.Entity<OwnerFeeInvoice>(entity =>
        {
            entity.Property(i => i.Status).HasMaxLength(20);
            entity.Property(i => i.Title).HasMaxLength(200);
            entity.HasOne(i => i.Owner)
                .WithMany()
                .HasForeignKey(i => i.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(i => new { i.OwnerId, i.Status });
        });

        modelBuilder.Entity<OwnerFeeInvoiceItem>(entity =>
        {
            entity.HasOne(i => i.Invoice)
                .WithMany(inv => inv.Items)
                .HasForeignKey(i => i.InvoiceId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(i => i.Booking)
                .WithMany()
                .HasForeignKey(i => i.BookingId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(i => i.BookingId).IsUnique();
        });

        modelBuilder.Entity<PlatformPayment>(entity =>
        {
            entity.Property(p => p.Gateway).HasMaxLength(20);
            entity.Property(p => p.Status).HasMaxLength(20);
            entity.Property(p => p.TransactionToken).HasMaxLength(64);
            entity.Property(p => p.ProviderReference).HasMaxLength(128);
            entity.HasOne(p => p.Invoice)
                .WithMany(i => i.Payments)
                .HasForeignKey(p => p.InvoiceId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(p => p.Owner)
                .WithMany()
                .HasForeignKey(p => p.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(p => p.TransactionToken).IsUnique();
            entity.HasIndex(p => new { p.OwnerId, p.Status });
            entity.HasIndex(p => p.GatewayTransactionId).IsUnique();
        });

        modelBuilder.Entity<BookingPayment>(entity =>
        {
            entity.Property(p => p.Gateway).HasMaxLength(20);
            entity.Property(p => p.Status).HasMaxLength(20);
            entity.Property(p => p.TransactionToken).HasMaxLength(64);
            entity.HasOne(p => p.Booking)
                .WithMany()
                .HasForeignKey(p => p.BookingId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(p => p.User)
                .WithMany()
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(p => p.TransactionToken).IsUnique();
            entity.HasIndex(p => new { p.BookingId, p.Status });
        });
    }
}
