using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Riyada.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentGatewayTransactionId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "GatewayTransactionId",
                table: "PlatformPayments",
                type: "TEXT",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_PlatformPayments_GatewayTransactionId",
                table: "PlatformPayments",
                column: "GatewayTransactionId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PlatformPayments_GatewayTransactionId",
                table: "PlatformPayments");

            migrationBuilder.DropColumn(
                name: "GatewayTransactionId",
                table: "PlatformPayments");
        }
    }
}
