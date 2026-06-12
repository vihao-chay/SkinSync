using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class SchemaMigration1
{
    public long Version { get; set; }

    public DateTime? InsertedAt { get; set; }
}
