<?php

namespace Database\Seeders;


use Inova\NovaAdmin\Database\Seeders\NovaAdminSeeder;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call(NovaAdminSeeder::class);
    }
}
