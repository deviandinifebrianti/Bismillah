# Generated by Django 3.2.25 on 2025-05-08 15:15

from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('sipreti', '0003_auto_20250507_2255'),
    ]

    operations = [
        migrations.CreateModel(
            name='KompresiArithmetic',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('id_pegawai', models.CharField(max_length=50)),
                ('width', models.IntegerField()),
                ('height', models.IntegerField()),
                ('frequency_model', models.JSONField(blank=True, null=True)),
                ('code_table', models.TextField(blank=True, null=True)),
                ('compressed_file', models.BinaryField()),
                ('compression_type', models.CharField(default='arithmetic', max_length=20)),
                ('original_length', models.IntegerField()),
                ('original_size', models.IntegerField(default=0)),
                ('compressed_size', models.IntegerField(default=0)),
                ('compression_ratio', models.FloatField(default=0.0)),
                ('compression_time_ms', models.IntegerField(default=0)),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
            ],
            options={
                'verbose_name': 'Kompresi Arithmetic',
                'verbose_name_plural': 'Kompresi Arithmetic',
            },
        ),
        migrations.CreateModel(
            name='BiometrikPegawaiGroup',
            fields=[
            ],
            options={
                'verbose_name': 'Biometrik (Dikelompokkan)',
                'verbose_name_plural': 'Biometrik (Dikelompokkan)',
                'proxy': True,
                'indexes': [],
                'constraints': [],
            },
            bases=('sipreti.biometrik',),
        ),
        migrations.RemoveField(
            model_name='kompresihuffman',
            name='is_rgb',
        ),
        migrations.RemoveField(
            model_name='kompresihuffman',
            name='timestamp',
        ),
        migrations.AlterField(
            model_name='pegawai',
            name='created_at',
            field=models.DateTimeField(default=django.utils.timezone.now),
        ),
        migrations.CreateModel(
            name='LogVerifikasiArithmetic',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('status_verifikasi', models.BooleanField()),
                ('nilai_kecocokan', models.FloatField(blank=True, null=True)),
                ('waktu_dekompresi_ms', models.IntegerField()),
                ('waktu_verifikasi_ms', models.IntegerField()),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('kompresi', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='sipreti.kompresiarithmetic')),
            ],
            options={
                'verbose_name': 'Log Verifikasi Arithmetic',
                'verbose_name_plural': 'Log Verifikasi Arithmetic',
            },
        ),
    ]
