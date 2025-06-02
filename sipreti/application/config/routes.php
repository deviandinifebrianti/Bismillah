<?php
defined('BASEPATH') OR exit('No direct script access allowed');

/*
| -------------------------------------------------------------------------
| URI ROUTING
| -------------------------------------------------------------------------
| This file lets you re-map URI requests to specific controller functions.
|
| Typically there is a one-to-one relationship between a URL string
| and its corresponding controller class/method. The segments in a
| URL normally follow this pattern:
|
|	example.com/class/method/id/
|
| In some instances, however, you may want to remap this relationship
| so that a different class/function is called than the one
| corresponding to the URL.
|
| Please see the user guide for complete details:
|
|	https://codeigniter.com/userguide3/general/routing.html
|
| -------------------------------------------------------------------------
| RESERVED ROUTES
| -------------------------------------------------------------------------
|
| There are three reserved routes:
|
|	$route['default_controller'] = 'welcome';
|
| This route indicates which controller class should be loaded if the
| URI contains no data. In the above example, the "welcome" class
| would be loaded.
|
|	$route['404_override'] = 'errors/page_missing';
|
| This route will tell the Router which controller/method to use if those
| provided in the URL cannot be matched to a valid route.
|
|	$route['translate_uri_dashes'] = FALSE;
|
| This is not exactly a route, but allows you to automatically route
| controller and method names that contain dashes. '-' isn't a valid
| class or method name character, so it requires translation.
| When you set this option to TRUE, it will replace ALL dashes in the
| controller and method URI segments.
|
| Examples:	my-controller/index	-> my_controller/index
|		my-controller/my-method	-> my_controller/my_method
*/
$route['default_controller'] = 'welcome';
$route['404_override'] = '';
$route['translate_uri_dashes'] = FALSE;
$route['biometrik/add_image'] = 'BiometrikController/add_image';
$route['biometrik/verify_image'] = 'BiometrikController/verify_image';

$route['pegawai'] = 'Pegawai/index';
$route['jabatan'] = 'Jabatan/index';
$route['radius_absen'] = 'Radius_absen/index';
$route['log_absensi'] = 'Log_absensi/index';
$route['unit_kerja'] = 'Unit_kerja/index';
$route['user_android'] = 'User_android/index';
$route['vektor_pegawai'] = 'Vektor_pegawai/index';
$route['radius_absen/get_detail_json/(:num)'] = 'radius_absen/get_detail_json/$1';
$route['api/add_image'] = 'api/add_image';
$route['pegawai/vektor/(:any)'] = 'pegawai/lihat_vektor/$1';
$route['vektor_pegawai/update_foto/(:num)'] = 'vektor_pegawai/update_foto_pegawai/$1';
$route['pegawai/list'] = 'pegawai/list';
$route['pegawai/detail/(:num)'] = 'pegawai/detail/$1';
$route['pegawai/photo/(:num)'] = 'pegawai/photo/$1';
$route['pegawai/media/(.+)'] = 'pegawai/media/$1';

$route['verifikasi'] = 'verifikasi/index';
$route['verifikasi/detail/(:num)'] = 'verifikasi/detail/$1';
$route['verifikasi/tampilkan_hasil/(:num)'] = 'verifikasi/tampilkan_hasil/$1';
$route['verifikasi/proses_verifikasi/(:num)'] = 'verifikasi/proses_verifikasi/$1';



$route['biometrik'] = 'biometrik/index';
$route['biometrik/biometrik_form'] = 'biometrik/biometrik_form';
$route['biometrik/simpan'] = 'biometrik/simpan';
$route['biometrik/delete/(:num)'] = 'biometrik/delete/$1';
