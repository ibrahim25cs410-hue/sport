using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace Riyada.Api.Tests;

public class HealthAndPaginationTests : IClassFixture<RiyadaWebApplicationFactory>
{
    private readonly HttpClient _client;

    public HealthAndPaginationTests(RiyadaWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Health_returns_ok()
    {
        var res = await _client.GetAsync("/api/health");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task Fields_without_paging_returns_json_array()
    {
        var res = await _client.GetAsync("/api/fields");
        res.EnsureSuccessStatusCode();
        var body = await res.Content.ReadAsStringAsync();
        Assert.StartsWith("[", body.Trim());
    }

    [Fact]
    public async Task Fields_with_paging_returns_paged_object()
    {
        var res = await _client.GetAsync("/api/fields?page=1&limit=5");
        res.EnsureSuccessStatusCode();
        var body = await res.Content.ReadAsStringAsync();
        Assert.Contains("\"items\"", body);
        Assert.Contains("\"hasNextPage\"", body);
    }
}
