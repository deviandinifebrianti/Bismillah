from rest_framework import serializers
from .models import Biometrik
from .models import LogAbsensi  
from .models import Pegawai
from .models import Jabatan, UnitKerja, RadiusAbsen
from django.contrib.auth.models import User

class BiometrikSerializer(serializers.ModelSerializer):
    image = serializers.ImageField(use_url=True)

    class Meta:
        model = Biometrik
        fields = ['id_pegawai', 'face_id', 'created_at', 'updated_at']
        # Jika Anda ingin mengakses semua field, Anda bisa tulis fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password']

class JabatanSerializer(serializers.ModelSerializer):
    class Meta:
        model = Jabatan
        fields = '__all__'

class PegawaiSerializer(serializers.ModelSerializer):
    user = UserSerializer()

    class Meta:
        model = Pegawai
        fields = ['nip', 'no_hp', 'id_unit_kerja', 'user']

    def create(self, validated_data):
        user_data = validated_data.pop('user')
        user = User.objects.create_user(**user_data)
        pegawai = Pegawai.objects.create(user=user, **validated_data)
        return pegawai

class LogAbsensiSerializer(serializers.ModelSerializer):
    class Meta:
        model = LogAbsensi
        fields = '__all__'

class RadiusAbsenSerializer(serializers.ModelSerializer):
    class Meta:
        model = RadiusAbsen
        fields = '__all__'

class UnitKerjaSerializer(serializers.ModelSerializer):

    class Meta:
        model = UnitKerja
        fields = ['id_unit_kerja', 'nama_unit_kerja', 'latitude', 'longitude', 'radius']