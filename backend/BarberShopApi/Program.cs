using System.Data;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
});

var app = builder.Build();
app.UseCors();

var connectionString = builder.Configuration.GetConnectionString("BarberShopDB")
    ?? throw new InvalidOperationException("Missing connection string BarberShopDB.");

const string demoPassword = "123456";
const string placeholderHash = "REPLACE_WITH_REAL_PASSWORD_HASH";

app.MapGet("/api/health", async () =>
{
    await using var conn = new SqlConnection(connectionString);
    await conn.OpenAsync();
    return Results.Ok(new { status = "ok", database = conn.Database });
});

app.MapPost("/api/auth/login", async (LoginRequest request) =>
{
    if (string.IsNullOrWhiteSpace(request.Phone) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Phone and password are required." });
    }

    await using var conn = new SqlConnection(connectionString);
    await conn.OpenAsync();

    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        SELECT UserId, Role, FullName, Phone, Email, PasswordHash, AvatarUrl, Gender, DateOfBirth, IsActive
        FROM dbo.Users
        WHERE Phone = @phone
        """;
    cmd.Parameters.Add(new SqlParameter("@phone", SqlDbType.VarChar, 20) { Value = request.Phone.Trim() });

    await using var reader = await cmd.ExecuteReaderAsync();
    if (!await reader.ReadAsync())
    {
        return Results.Json(new { message = "Số điện thoại hoặc mật khẩu không đúng." }, statusCode: 401);
    }

    var passwordHash = reader.GetString(reader.GetOrdinal("PasswordHash"));
    var passwordOk = request.Password == passwordHash
        || (passwordHash == placeholderHash && request.Password == demoPassword);
    if (!passwordOk)
    {
        return Results.Json(new { message = "Số điện thoại hoặc mật khẩu không đúng." }, statusCode: 401);
    }

    if (!reader.GetBoolean(reader.GetOrdinal("IsActive")))
    {
        return Results.Json(new { message = "Tài khoản đã bị khóa." }, statusCode: 403);
    }

    return Results.Ok(MapUser(reader));
});

app.MapGet("/api/staff/{barberId:int}/dashboard", async (int barberId) =>
{
    await using var conn = new SqlConnection(connectionString);
    await conn.OpenAsync();

    var user = await QueryUserAsync(conn, barberId);
    if (user is null)
    {
        return Results.NotFound(new { message = "Không tìm thấy người dùng." });
    }

    var barber = await QueryBarberAsync(conn, barberId);
    if (barber is null)
    {
        return Results.NotFound(new { message = "Người dùng này không có hồ sơ barber." });
    }

    await SyncBarberWorkStatusAsync(conn, barberId);
    barber = await QueryBarberAsync(conn, barberId);

    var bookings = await QueryBookingsAsync(conn, barberId);
    var reviews = await QueryReviewsAsync(conn, barberId);
    var schedules = await QuerySchedulesAsync(conn, barberId);

    return Results.Ok(new
    {
        user,
        barber,
        bookings,
        reviews,
        schedules,
        timeSlots = DefaultTimeSlots()
    });
});

app.MapPost("/api/staff/{barberId:int}/bookings/{bookingId:int}/complete", async (int barberId, int bookingId) =>
{
    await using var conn = new SqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        UPDATE dbo.Bookings
        SET Status = 'completed', UpdatedAt = SYSUTCDATETIME()
        WHERE BookingId = @bookingId
          AND BarberId = @barberId
          AND Status NOT IN ('completed', 'cancelled', 'no_show')
        """;
    cmd.Parameters.Add(new SqlParameter("@bookingId", SqlDbType.Int) { Value = bookingId });
    cmd.Parameters.Add(new SqlParameter("@barberId", SqlDbType.Int) { Value = barberId });

    var rows = await cmd.ExecuteNonQueryAsync();
    if (rows == 0)
    {
        return Results.BadRequest(new { message = "Không thể hoàn thành ca này." });
    }

    await SyncBarberWorkStatusAsync(conn, barberId);
    return Results.Ok(new { bookingId, status = "completed" });
});

app.MapPatch("/api/bookings/{bookingId:int}/status", async (int bookingId, StatusRequest request) =>
{
    var allowed = new[] { "pending", "confirmed", "checked_in", "in_progress", "completed", "cancelled", "no_show" };
    if (!allowed.Contains(request.Status))
    {
        return Results.BadRequest(new { message = "Trạng thái không hợp lệ." });
    }

    await using var conn = new SqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        UPDATE dbo.Bookings
        SET Status = @status, UpdatedAt = SYSUTCDATETIME()
        WHERE BookingId = @id
        """;
    cmd.Parameters.Add(new SqlParameter("@status", SqlDbType.VarChar, 20) { Value = request.Status });
    cmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = bookingId });

    var rows = await cmd.ExecuteNonQueryAsync();
    return rows == 0
        ? Results.NotFound(new { message = "Không tìm thấy lịch hẹn." })
        : Results.Ok(new { bookingId, status = request.Status });
});

app.Run();

static async Task SyncBarberWorkStatusAsync(SqlConnection conn, int barberId)
{
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        UPDATE dbo.Bookings
        SET Status = 'in_progress', UpdatedAt = SYSUTCDATETIME()
        WHERE BarberId = @id
          AND BookingDate = CONVERT(date, GETDATE())
          AND Status IN ('pending', 'confirmed', 'checked_in')
          AND StartTime <= CONVERT(time(0), GETDATE())
          AND EndTime > CONVERT(time(0), GETDATE());

        DECLARE @onShift bit = CASE WHEN EXISTS (
            SELECT 1 FROM dbo.BarberSchedules
            WHERE BarberId = @id
              AND WorkDate = CONVERT(date, GETDATE())
              AND IsDayOff = 0
              AND StartTime <= CONVERT(time(0), GETDATE())
              AND EndTime > CONVERT(time(0), GETDATE())
        ) THEN 1 ELSE 0 END;

        DECLARE @busy bit = CASE WHEN EXISTS (
            SELECT 1 FROM dbo.Bookings
            WHERE BarberId = @id
              AND BookingDate = CONVERT(date, GETDATE())
              AND Status = 'in_progress'
        ) THEN 1 ELSE 0 END;

        DECLARE @onBreak bit = CASE
            WHEN @onShift = 0 AND EXISTS (
                SELECT 1 FROM dbo.BarberSchedules
                WHERE BarberId = @id
                  AND WorkDate = CONVERT(date, GETDATE())
                  AND IsDayOff = 0
                  AND CONVERT(time(0), GETDATE()) > (
                      SELECT MIN(StartTime) FROM dbo.BarberSchedules
                      WHERE BarberId = @id AND WorkDate = CONVERT(date, GETDATE()) AND IsDayOff = 0
                  )
                  AND CONVERT(time(0), GETDATE()) < (
                      SELECT MAX(EndTime) FROM dbo.BarberSchedules
                      WHERE BarberId = @id AND WorkDate = CONVERT(date, GETDATE()) AND IsDayOff = 0
                  )
            ) THEN 1 ELSE 0 END;

        DECLARE @status varchar(20) =
            CASE
                WHEN @busy = 1 THEN 'busy'
                WHEN @onShift = 1 THEN 'available'
                WHEN @onBreak = 1 THEN 'break'
                ELSE 'off'
            END;

        UPDATE dbo.BarberProfiles
        SET Status = @status, StatusUpdatedAt = SYSUTCDATETIME()
        WHERE BarberId = @id;
        """;
    cmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = barberId });
    await cmd.ExecuteNonQueryAsync();
}

static async Task<List<object>> QuerySchedulesAsync(SqlConnection conn, int barberId)
{
    var schedules = new List<object>();
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        SELECT ScheduleId, BarberId, WorkDate, StartTime, EndTime, IsDayOff, Note
        FROM dbo.BarberSchedules
        WHERE BarberId = @id
        ORDER BY WorkDate, StartTime
        """;
    cmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = barberId });
    await using var reader = await cmd.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        schedules.Add(new
        {
            id = reader.GetInt32(reader.GetOrdinal("ScheduleId")),
            staffId = reader.GetInt32(reader.GetOrdinal("BarberId")),
            workDate = reader.GetDateTime(reader.GetOrdinal("WorkDate")).ToString("yyyy-MM-dd"),
            startTime = ((TimeSpan)reader.GetValue(reader.GetOrdinal("StartTime"))).ToString(@"hh\:mm"),
            endTime = ((TimeSpan)reader.GetValue(reader.GetOrdinal("EndTime"))).ToString(@"hh\:mm"),
            isDayOff = reader.GetBoolean(reader.GetOrdinal("IsDayOff")),
            note = reader.IsDBNull(reader.GetOrdinal("Note")) ? null : reader.GetString(reader.GetOrdinal("Note")),
        });
    }

    return schedules;
}

static string[] DefaultTimeSlots() =>
[
    "08:00", "09:00", "10:00", "11:00",
    "13:00", "14:00", "15:00", "16:00",
    "17:00", "18:00", "19:00", "20:00"
];

static string MapAppRole(string dbRole) => dbRole == "barber" ? "staff" : dbRole;

static object MapUser(SqlDataReader reader)
{
    var dobOrd = reader.GetOrdinal("DateOfBirth");
    return new
    {
        id = reader.GetInt32(reader.GetOrdinal("UserId")),
        role = MapAppRole(reader.GetString(reader.GetOrdinal("Role"))),
        fullName = reader.GetString(reader.GetOrdinal("FullName")),
        phone = reader.GetString(reader.GetOrdinal("Phone")),
        email = reader.IsDBNull(reader.GetOrdinal("Email")) ? null : reader.GetString(reader.GetOrdinal("Email")),
        avatarUrl = reader.IsDBNull(reader.GetOrdinal("AvatarUrl")) ? null : reader.GetString(reader.GetOrdinal("AvatarUrl")),
        gender = reader.IsDBNull(reader.GetOrdinal("Gender")) ? null : reader.GetString(reader.GetOrdinal("Gender")),
        dateOfBirth = reader.IsDBNull(dobOrd) ? null : reader.GetDateTime(dobOrd).ToString("yyyy-MM-dd"),
        isActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
    };
}

static async Task<object?> QueryUserAsync(SqlConnection conn, int userId)
{
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        SELECT UserId, Role, FullName, Phone, Email, AvatarUrl, Gender, DateOfBirth, IsActive
        FROM dbo.Users
        WHERE UserId = @id
        """;
    cmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = userId });
    await using var reader = await cmd.ExecuteReaderAsync();
    if (!await reader.ReadAsync()) return null;
    return MapUser(reader);
}

static async Task<object?> QueryBarberAsync(SqlConnection conn, int barberId)
{
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        SELECT u.UserId, u.FullName, u.Phone, u.AvatarUrl,
               bp.Bio, bp.Specialty, bp.YearsExperience, bp.Status,
               bp.AverageRating, bp.ReviewCount
        FROM dbo.BarberProfiles bp
        INNER JOIN dbo.Users u ON u.UserId = bp.BarberId
        WHERE bp.BarberId = @id
        """;
    cmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = barberId });
    await using var reader = await cmd.ExecuteReaderAsync();
    if (!await reader.ReadAsync()) return null;

    return new
    {
        userId = reader.GetInt32(reader.GetOrdinal("UserId")),
        fullName = reader.GetString(reader.GetOrdinal("FullName")),
        phone = reader.GetString(reader.GetOrdinal("Phone")),
        avatarUrl = reader.IsDBNull(reader.GetOrdinal("AvatarUrl")) ? null : reader.GetString(reader.GetOrdinal("AvatarUrl")),
        bio = reader.IsDBNull(reader.GetOrdinal("Bio")) ? "" : reader.GetString(reader.GetOrdinal("Bio")),
        specialty = reader.IsDBNull(reader.GetOrdinal("Specialty")) ? "" : reader.GetString(reader.GetOrdinal("Specialty")),
        yearsExperience = Convert.ToInt32(reader.GetValue(reader.GetOrdinal("YearsExperience"))),
        status = reader.GetString(reader.GetOrdinal("Status")),
        avgRating = Convert.ToDouble(reader.GetValue(reader.GetOrdinal("AverageRating"))),
        reviewCount = reader.GetInt32(reader.GetOrdinal("ReviewCount")),
        portfolioImages = Array.Empty<string>(),
    };
}

static async Task<List<object>> QueryBookingsAsync(SqlConnection conn, int barberId)
{
    var bookings = new List<(int Id, object Dto)>();

    await using (var cmd = conn.CreateCommand())
    {
        cmd.CommandText = """
            SELECT b.BookingId, b.CustomerId, b.BarberId, b.BookingDate, b.StartTime, b.EndTime,
                   b.Status, b.TotalPrice, b.CustomerNote, b.CreatedAt,
                   bu.FullName AS BarberName, bu.AvatarUrl AS BarberAvatar
            FROM dbo.Bookings b
            INNER JOIN dbo.Users bu ON bu.UserId = b.BarberId
            WHERE b.BarberId = @id
            ORDER BY b.BookingDate, b.StartTime
            """;
        cmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = barberId });
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var id = reader.GetInt32(reader.GetOrdinal("BookingId"));
            bookings.Add((id, new Dictionary<string, object?>
            {
                ["id"] = id,
                ["customerId"] = reader.GetInt32(reader.GetOrdinal("CustomerId")),
                ["staffId"] = reader.GetInt32(reader.GetOrdinal("BarberId")),
                ["staffName"] = reader.GetString(reader.GetOrdinal("BarberName")),
                ["staffAvatar"] = reader.IsDBNull(reader.GetOrdinal("BarberAvatar")) ? null : reader.GetString(reader.GetOrdinal("BarberAvatar")),
                ["bookingDate"] = reader.GetDateTime(reader.GetOrdinal("BookingDate")).ToString("yyyy-MM-dd"),
                ["startTime"] = ((TimeSpan)reader.GetValue(reader.GetOrdinal("StartTime"))).ToString(@"hh\:mm"),
                ["endTime"] = ((TimeSpan)reader.GetValue(reader.GetOrdinal("EndTime"))).ToString(@"hh\:mm"),
                ["status"] = reader.GetString(reader.GetOrdinal("Status")),
                ["totalPrice"] = Convert.ToDouble(reader.GetValue(reader.GetOrdinal("TotalPrice"))),
                ["note"] = reader.IsDBNull(reader.GetOrdinal("CustomerNote")) ? null : reader.GetString(reader.GetOrdinal("CustomerNote")),
                ["createdAt"] = reader.GetDateTime(reader.GetOrdinal("CreatedAt")).ToString("o"),
                ["services"] = new List<object>(),
            }));
        }
    }

    if (bookings.Count == 0) return [];

    var servicesByBooking = new Dictionary<int, List<object>>();
    await using (var cmd = conn.CreateCommand())
    {
        var ids = bookings.Select(b => b.Id).ToArray();
        var paramNames = ids.Select((_, i) => $"@id{i}").ToArray();
        cmd.CommandText = $"""
            SELECT bs.BookingId, s.ServiceId, s.Name, s.Description, bs.PriceAtBooking,
                   bs.DurationMinutes, s.ImageUrl, s.IsActive
            FROM dbo.BookingServices bs
            INNER JOIN dbo.Services s ON s.ServiceId = bs.ServiceId
            WHERE bs.BookingId IN ({string.Join(",", paramNames)})
            """;
        for (var i = 0; i < ids.Length; i++)
        {
            cmd.Parameters.Add(new SqlParameter(paramNames[i], SqlDbType.Int) { Value = ids[i] });
        }

        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var bookingId = reader.GetInt32(reader.GetOrdinal("BookingId"));
            if (!servicesByBooking.TryGetValue(bookingId, out var list))
            {
                list = [];
                servicesByBooking[bookingId] = list;
            }

            list.Add(new
            {
                id = reader.GetInt32(reader.GetOrdinal("ServiceId")),
                name = reader.GetString(reader.GetOrdinal("Name")),
                description = reader.IsDBNull(reader.GetOrdinal("Description")) ? "" : reader.GetString(reader.GetOrdinal("Description")),
                price = Convert.ToDouble(reader.GetValue(reader.GetOrdinal("PriceAtBooking"))),
                durationMin = Convert.ToInt32(reader.GetValue(reader.GetOrdinal("DurationMinutes"))),
                imageUrl = reader.IsDBNull(reader.GetOrdinal("ImageUrl")) ? "" : reader.GetString(reader.GetOrdinal("ImageUrl")),
                isActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            });
        }
    }

    foreach (var (id, dto) in bookings)
    {
        var dict = (Dictionary<string, object?>)dto;
        dict["services"] = servicesByBooking.GetValueOrDefault(id) ?? [];
    }

    return bookings.Select(b => b.Dto).ToList();
}

static async Task<List<object>> QueryReviewsAsync(SqlConnection conn, int barberId)
{
    var reviews = new List<object>();
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        SELECT r.ReviewId, r.BookingId, r.CustomerId, r.BarberId, r.Rating, r.Comment, r.CreatedAt,
               u.FullName AS CustomerName, u.AvatarUrl AS CustomerAvatar
        FROM dbo.Reviews r
        INNER JOIN dbo.Users u ON u.UserId = r.CustomerId
        WHERE r.BarberId = @id
        ORDER BY r.CreatedAt DESC
        """;
    cmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = barberId });
    await using var reader = await cmd.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        reviews.Add(new
        {
            id = reader.GetInt32(reader.GetOrdinal("ReviewId")),
            bookingId = reader.GetInt32(reader.GetOrdinal("BookingId")),
            customerId = reader.GetInt32(reader.GetOrdinal("CustomerId")),
            customerName = reader.GetString(reader.GetOrdinal("CustomerName")),
            customerAvatar = reader.IsDBNull(reader.GetOrdinal("CustomerAvatar")) ? null : reader.GetString(reader.GetOrdinal("CustomerAvatar")),
            staffId = reader.GetInt32(reader.GetOrdinal("BarberId")),
            rating = Convert.ToInt32(reader.GetValue(reader.GetOrdinal("Rating"))),
            comment = reader.IsDBNull(reader.GetOrdinal("Comment")) ? "" : reader.GetString(reader.GetOrdinal("Comment")),
            createdAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")).ToString("o"),
        });
    }

    return reviews;
}

internal record LoginRequest(string Phone, string Password);
internal record StatusRequest(string Status);
