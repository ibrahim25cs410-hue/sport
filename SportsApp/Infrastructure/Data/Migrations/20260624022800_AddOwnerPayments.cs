using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Riyada.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddOwnerPayments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "OwnerFeeInvoices",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    OwnerId = table.Column<int>(type: "INTEGER", nullable: false),
                    Amount = table.Column<int>(type: "INTEGER", nullable: false),
                    TotalHours = table.Column<int>(type: "INTEGER", nullable: false),
                    Status = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    Title = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    PaidAt = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OwnerFeeInvoices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OwnerFeeInvoices_Users_OwnerId",
                        column: x => x.OwnerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "OwnerFeeInvoiceItems",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    InvoiceId = table.Column<int>(type: "INTEGER", nullable: false),
                    BookingId = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OwnerFeeInvoiceItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OwnerFeeInvoiceItems_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_OwnerFeeInvoiceItems_OwnerFeeInvoices_InvoiceId",
                        column: x => x.InvoiceId,
                        principalTable: "OwnerFeeInvoices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PlatformPayments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    InvoiceId = table.Column<int>(type: "INTEGER", nullable: false),
                    OwnerId = table.Column<int>(type: "INTEGER", nullable: false),
                    Amount = table.Column<int>(type: "INTEGER", nullable: false),
                    Gateway = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    TransactionToken = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    ProviderReference = table.Column<string>(type: "TEXT", maxLength: 128, nullable: true),
                    Status = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    VerifiedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PlatformPayments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PlatformPayments_OwnerFeeInvoices_InvoiceId",
                        column: x => x.InvoiceId,
                        principalTable: "OwnerFeeInvoices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PlatformPayments_Users_OwnerId",
                        column: x => x.OwnerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_OwnerFeeInvoiceItems_BookingId",
                table: "OwnerFeeInvoiceItems",
                column: "BookingId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_OwnerFeeInvoiceItems_InvoiceId",
                table: "OwnerFeeInvoiceItems",
                column: "InvoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_OwnerFeeInvoices_OwnerId_Status",
                table: "OwnerFeeInvoices",
                columns: new[] { "OwnerId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_PlatformPayments_InvoiceId",
                table: "PlatformPayments",
                column: "InvoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_PlatformPayments_OwnerId_Status",
                table: "PlatformPayments",
                columns: new[] { "OwnerId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_PlatformPayments_TransactionToken",
                table: "PlatformPayments",
                column: "TransactionToken",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "OwnerFeeInvoiceItems");
            migrationBuilder.DropTable(name: "PlatformPayments");
            migrationBuilder.DropTable(name: "OwnerFeeInvoices");
        }
    }
}
