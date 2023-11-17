using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;

class Program
{
    static async Task Main(string[] args)
    {
        var filePath = "/app/publish/sample_data_to_transform.csv";
        var sizeLimit = 1024L * 1024L * 1024L; // 1GB
        var batchSize = 10000;
        var currentSize = 0L;
        var idCounter = 1;

        var start = new DateTime(2020, 1, 1);
        var end = new DateTime(2023, 1, 1);
        var random = new Random();

        using (var fileStream = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None, 4096, true))
        using (var streamWriter = new StreamWriter(fileStream))
        {
            await streamWriter.WriteLineAsync("id,name,timestamp,value");

            while (currentSize < sizeLimit)
            {
                var stringBuilder = new StringBuilder();

                for (int i = 0; i < batchSize; i++)
                {
                    var line = $"{idCounter++},{RandomString(10)},{RandomDate(start, end):yyyy-MM-dd HH:mm:ss},{random.NextDouble() * 1000}";
                    stringBuilder.AppendLine(line);
                }

                await streamWriter.WriteAsync(stringBuilder.ToString());
                currentSize = fileStream.Length;
                //Console.Write(".");
            }
        }

        Console.WriteLine("File generation completed.");
    }

    static string RandomString(int length)
    {
        const string chars = "abcdefghijklmnopqrstuvwxyz";
        var random = new Random();
        var stringChars = new char[length];
        for (int i = 0; i < length; i++)
        {
            stringChars[i] = chars[random.Next(chars.Length)];
        }
        return new string(stringChars);
    }

    static DateTime RandomDate(DateTime start, DateTime end)
    {
        var random = new Random();
        var range = (end - start).Days;
        return start.AddDays(random.Next(range));
    }
}
