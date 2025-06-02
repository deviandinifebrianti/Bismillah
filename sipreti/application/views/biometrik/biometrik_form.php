<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tambah Biometrik - SI Preti</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #7c3aed 0%, #a855f7 100%);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* Header */
        .header {
            background: rgba(139, 69, 19, 0.9);
            color: white;
            padding: 1rem 2rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .logo-icon {
            width: 50px;
            height: 50px;
            background: #22c55e;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
        }

        .logo-icon::before {
            content: "👤";
            font-size: 20px;
        }

        .logo-icon::after {
            content: "🕐";
            font-size: 12px;
            position: absolute;
            bottom: -2px;
            right: -2px;
            background: white;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .logo-text {
            font-size: 1.8rem;
            font-weight: bold;
            color: white;
        }

        .logo-subtitle {
            font-size: 0.9rem;
            opacity: 0.9;
            color: #e0e0e0;
        }

        .nav {
            display: flex;
            gap: 2rem;
        }

        .nav a {
            color: white;
            text-decoration: none;
            padding: 0.75rem 1.5rem;
            border-radius: 6px;
            transition: background-color 0.3s;
            font-weight: 500;
        }

        .nav a:hover, .nav a.active {
            background-color: rgba(255, 255, 255, 0.15);
        }

        /* Main Content */
        .main-content {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem;
        }

        /* Card */
        .card {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            overflow: hidden;
            width: 100%;
            max-width: 500px;
            animation: slideUp 0.6s ease-out;
        }

        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .card-header {
            background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
            color: white;
            padding: 2rem;
            text-align: center;
        }

        .card-title {
            font-size: 1.5rem;
            font-weight: bold;
            margin: 0;
        }

        .card-body {
            padding: 2.5rem;
        }

        /* Form */
        .form-group {
            margin-bottom: 1.5rem;
        }

        .form-label {
            display: block;
            font-weight: 600;
            color: #374151;
            margin-bottom: 0.5rem;
            font-size: 0.95rem;
        }

        /* Search Box with Dropdown */
        .search-container {
            position: relative;
        }

        .search-box {
            position: relative;
            margin-bottom: 0;
        }

        .search-input {
            width: 100%;
            padding: 0.75rem 1rem 0.75rem 2.5rem;
            border: 2px solid #e5e7eb;
            border-radius: 12px;
            font-size: 1rem;
            transition: all 0.3s ease;
            background: white;
        }

        .search-input:focus {
            outline: none;
            border-color: #22c55e;
            box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.1);
        }

        .search-icon {
            position: absolute;
            left: 0.75rem;
            top: 50%;
            transform: translateY(-50%);
            color: #9ca3af;
            z-index: 1;
        }

        /* Dropdown List */
        .dropdown-list {
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            border: 2px solid #e5e7eb;
            border-top: 1px solid #e5e7eb;
            border-radius: 0 0 12px 12px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 1000;
            display: none;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .dropdown-list::-webkit-scrollbar {
            width: 6px;
        }

        .dropdown-list::-webkit-scrollbar-track {
            background: #f1f5f9;
        }

        .dropdown-list::-webkit-scrollbar-thumb {
            background: #cbd5e1;
            border-radius: 3px;
        }

        .dropdown-list::-webkit-scrollbar-thumb:hover {
            background: #94a3b8;
        }

        .dropdown-list.show {
            display: block;
        }

        .dropdown-item {
            padding: 12px 16px;
            cursor: pointer;
            border-bottom: 1px solid #f3f4f6;
            transition: background-color 0.2s;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .dropdown-item:hover {
            background-color: #f8fafc;
        }

        .dropdown-item:last-child {
            border-bottom: none;
        }

        .dropdown-item.selected {
            background-color: #f0fdf4;
            border-left: 3px solid #22c55e;
        }

        .employee-mini-avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 12px;
            flex-shrink: 0;
        }

        .employee-mini-avatar img {
            width: 100%;
            height: 100%;
            border-radius: 50%;
            object-fit: cover;
        }

        .employee-info {
            flex: 1;
        }

        .employee-mini-name {
            font-weight: 600;
            color: #1f2937;
            margin-bottom: 2px;
            font-size: 14px;
        }

        .employee-mini-nip {
            font-size: 12px;
            color: #6b7280;
        }

        .no-results {
            padding: 16px;
            text-align: center;
            color: #9ca3af;
            font-style: italic;
        }

        /* Hidden Select Input */
        .hidden-select {
            display: none;
        }

        /* Employee Preview */
        .employee-preview {
            background: #f8fafc;
            border: 2px dashed #e5e7eb;
            border-radius: 12px;
            padding: 1.5rem;
            text-align: center;
            margin-bottom: 1.5rem;
            min-height: 120px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
        }

        .employee-preview.selected {
            border-color: #22c55e;
            background: #f0fdf4;
            border-style: solid;
        }

        .employee-avatar {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid #22c55e;
            margin-bottom: 0.5rem;
        }

        .employee-name {
            font-weight: 600;
            color: #1f2937;
            margin-bottom: 0.25rem;
        }

        .employee-nip {
            font-size: 0.875rem;
            color: #6b7280;
        }

        .no-selection {
            color: #9ca3af;
            font-style: italic;
        }

        /* Buttons */
        .button-group {
            display: flex;
            gap: 1rem;
            margin-top: 2rem;
        }

        .btn {
            flex: 1;
            padding: 0.875rem 1.5rem;
            border: none;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            text-align: center;
            transition: all 0.3s ease;
            display: inline-block;
        }

        .btn-secondary {
            background: #f3f4f6;
            color: #374151;
            border: 2px solid #e5e7eb;
        }

        .btn-secondary:hover {
            background: #e5e7eb;
            transform: translateY(-1px);
        }

        .btn-primary {
            background: linear-gradient(135deg, #9333ea 0%, #7c3aed 100%);
            color: white;
            box-shadow: 0 4px 14px rgba(147, 51, 234, 0.3);
        }

        .btn-primary:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(147, 51, 234, 0.4);
        }

        .btn-primary:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
        }

        /* Loading state */
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 2px solid #ffffff;
            border-radius: 50%;
            border-top-color: transparent;
            animation: spin 1s ease-in-out infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* Responsive */
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                gap: 1rem;
                text-align: center;
            }

            .nav {
                flex-wrap: wrap;
                justify-content: center;
                gap: 1rem;
            }

            .main-content {
                padding: 1rem;
            }

            .card {
                max-width: 100%;
            }

            .card-body {
                padding: 1.5rem;
            }

            .button-group {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="logo">
            <div class="logo-icon"></div>
            <div>
                <div class="logo-text">SI Preti</div>
                <div class="logo-subtitle">Sistem Informasi Presensi Terkini</div>
            </div>
        </div>
        <nav class="nav">
            <a href="#">Dashboard</a>
            <a href="#data-master">Data Master</a>
            <a href="#">Absensi</a>
            <a href="#">Pegawai</a>
            <a href="#">User Android</a>
            <a href="#" class="active">Vektor Pegawai</a>
        </nav>
    </header>

    <!-- Main Content -->
    <div class="main-content">
        <div class="card">
            <div class="card-header">
                <h1 class="card-title">Tambah Biometrik Pegawai</h1>
            </div>
            <div class="card-body">
                <form id="biometricForm" method="POST" action="#">
                    <!-- Search Employee with Dropdown -->
                    <div class="form-group">
                        <label class="form-label">Cari Pegawai</label>
                        <div class="search-container">
                            <div class="search-box">
                                <span class="search-icon">🔍</span>
                                <input type="text" class="search-input" id="employeeSearch" placeholder="Ketik nama atau NIP pegawai..." autocomplete="off">
                            </div>
                            <div class="dropdown-list" id="dropdownList">
                                <div class="no-results">Ketik untuk mencari pegawai...</div>
                            </div>
                        </div>
                        
                        <!-- Hidden select for form submission -->
                        <select name="employee_id" id="employeeSelect" class="hidden-select">
                            <option value="">Pilih Pegawai...</option>
                        </select>
                    </div>

                    <!-- Employee Preview -->
                    <div class="employee-preview" id="employeePreview">
                        <div class="no-selection">
                            Pilih pegawai untuk melihat preview
                        </div>
                    </div>

                    <!-- Action Buttons -->
                    <div class="button-group">
                        <a href="#" class="btn btn-secondary">Kembali</a>
                        <button type="submit" class="btn btn-primary" id="submitBtn" disabled>
                            Lanjutkan ke Kelola Biometrik
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        // Data pegawai dari database
        const employees = [
            <?php if (!empty($pegawai)): ?>
                <?php foreach ($pegawai as $index => $emp): ?>{
                    id: '<?= $emp->id ?>',
                    nama: '<?= addslashes($emp->nama ?? '') ?>',
                    nip: '<?= $emp->nip ?? '' ?>',
                    image: '<?= $emp->image ?? '' ?>',
                    jabatan: '<?= $emp->jabatan ?? '' ?>',
                    unit_kerja: '<?= $emp->unit_kerja ?? '' ?>'
                }<?= ($index < count($pegawai) - 1) ? ',' : '' ?>
                <?php endforeach; ?>
            <?php endif; ?>
        ];

        // Elements
        const searchInput = document.getElementById('employeeSearch');
        const dropdownList = document.getElementById('dropdownList');
        const employeeSelect = document.getElementById('employeeSelect');
        const employeePreview = document.getElementById('employeePreview');
        const submitBtn = document.getElementById('submitBtn');
        const form = document.getElementById('biometricForm');

        let filteredEmployees = [];
        let selectedEmployeeId = null;

        // Initialize dropdown options
        function initializeDropdown() {
            // Clear existing options except the first one
            employeeSelect.innerHTML = '<option value="">Pilih Pegawai...</option>';
            
            // Add all employees to select
            employees.forEach(emp => {
                const option = document.createElement('option');
                option.value = emp.id;
                option.textContent = `${emp.nama} - ${emp.nip}`;
                option.dataset.nama = emp.nama;
                option.dataset.nip = emp.nip;
                option.dataset.image = emp.image || '';
                option.dataset.jabatan = emp.jabatan || '';
                option.dataset.unitKerja = emp.unit_kerja || '';
                employeeSelect.appendChild(option);
            });
        }

        // Filter employees based on search term
        function filterEmployees(searchTerm) {
            if (!searchTerm.trim()) {
                return [];
            }

            return employees.filter(emp => 
                emp.nama.toLowerCase().includes(searchTerm.toLowerCase()) ||
                emp.nip.includes(searchTerm) ||
                (emp.jabatan && emp.jabatan.toLowerCase().includes(searchTerm.toLowerCase())) ||
                (emp.unit_kerja && emp.unit_kerja.toLowerCase().includes(searchTerm.toLowerCase()))
            );
        }

        // Render dropdown list
        function renderDropdown(employees) {
            if (employees.length === 0) {
                dropdownList.innerHTML = '<div class="no-results">Tidak ada pegawai yang ditemukan</div>';
                return;
            }

            const html = employees.map(emp => {
                const initials = emp.nama.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
                const avatarHtml = emp.image 
                    ? `<img src="<?= base_url('uploads/pegawai/') ?>${emp.image}" alt="Foto">`
                    : initials;

                return `
                    <div class="dropdown-item" data-id="${emp.id}" data-nama="${emp.nama}" data-nip="${emp.nip}" data-image="${emp.image || ''}" data-jabatan="${emp.jabatan || ''}" data-unit-kerja="${emp.unit_kerja || ''}">
                        <div class="employee-mini-avatar">${avatarHtml}</div>
                        <div class="employee-info">
                            <div class="employee-mini-name">${emp.nama}</div>
                            <div class="employee-mini-nip">NIP: ${emp.nip}</div>
                        </div>
                    </div>
                `;
            }).join('');

            dropdownList.innerHTML = html;

            // Add click events to dropdown items
            dropdownList.querySelectorAll('.dropdown-item').forEach(item => {
                item.addEventListener('click', function() {
                    selectEmployee(this);
                });
            });
        }

        // Select employee
        function selectEmployee(item) {
            const id = item.dataset.id;
            const nama = item.dataset.nama;
            const nip = item.dataset.nip;
            const image = item.dataset.image;
            const jabatan = item.dataset.jabatan;
            const unitKerja = item.dataset.unitKerja;

            selectedEmployeeId = id;
            searchInput.value = `${nama} - ${nip}`;
            employeeSelect.value = id;
            
            hideDropdown();
            updateEmployeePreview(id, nama, nip, image, jabatan, unitKerja);
        }

        // Update employee preview
        function updateEmployeePreview(id, nama, nip, image, jabatan, unitKerja) {
            if (!id) {
                employeePreview.innerHTML = '<div class="no-selection">Pilih pegawai untuk melihat preview</div>';
                employeePreview.classList.remove('selected');
                submitBtn.disabled = true;
                return;
            }

            const initials = nama.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
            let avatarHtml = '';
            
            if (image) {
                avatarHtml = `<img src="<?= base_url('uploads/pegawai/') ?>${image}" alt="Foto" class="employee-avatar">`;
            } else {
                avatarHtml = `<div class="employee-avatar" style="background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%); display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">${initials}</div>`;
            }

            employeePreview.innerHTML = `
                ${avatarHtml}
                <div class="employee-name">${nama}</div>
                <div class="employee-nip">NIP: ${nip}</div>
                ${jabatan ? `<div style="font-size: 0.8rem; color: #6b7280; margin-top: 0.5rem;">${jabatan}</div>` : ''}
                ${unitKerja ? `<div style="font-size: 0.75rem; color: #9ca3af;">${unitKerja}</div>` : ''}
            `;
            
            employeePreview.classList.add('selected');
            submitBtn.disabled = false;
        }

        // Show dropdown
        function showDropdown() {
            dropdownList.classList.add('show');
        }

        // Hide dropdown
        function hideDropdown() {
            setTimeout(() => {
                dropdownList.classList.remove('show');
            }, 200);
        }

        // Search input event listener
        searchInput.addEventListener('input', function() {
            const searchTerm = this.value;
            
            // Tampilkan dropdown hanya jika ada input
            if (searchTerm.length === 0) {
                hideDropdown();
                if (selectedEmployeeId) {
                    // Clear selection if search is cleared
                    selectedEmployeeId = null;
                    employeeSelect.value = '';
                    updateEmployeePreview();
                }
                return;
            }

            // Tampilkan dropdown setelah minimal 1 karakter
            if (searchTerm.length >= 1) {
                filteredEmployees = filterEmployees(searchTerm);
                renderDropdown(filteredEmployees);
                showDropdown();
            }

            // Reset highlight
            currentHighlight = -1;
        });

        // Search input focus/blur events
        searchInput.addEventListener('focus', function() {
            // Tampilkan semua pegawai saat focus jika belum ada input
            if (this.value.trim() === '' && !selectedEmployeeId) {
                filteredEmployees = employees;
                renderDropdown(filteredEmployees);
                showDropdown();
            } else if (this.value.trim() && !selectedEmployeeId) {
                showDropdown();
            }
        });

        searchInput.addEventListener('blur', function() {
            hideDropdown();
        });

        // Clear search when clicking on input if employee is selected
        searchInput.addEventListener('click', function() {
            if (selectedEmployeeId) {
                this.value = '';
                selectedEmployeeId = null;
                employeeSelect.value = '';
                updateEmployeePreview();
                hideDropdown();
            }
        });

        // Form submission
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const selectedEmployee = employeeSelect.value;
            if (!selectedEmployee) {
                alert('Silakan pilih pegawai terlebih dahulu');
                return;
            }

            // Show loading
            submitBtn.innerHTML = '<span class="loading"></span> Memproses...';
            submitBtn.disabled = true;

            // Simulate form submission
            setTimeout(() => {
                alert(`Form akan dikirim dengan Employee ID: ${selectedEmployee}`);
                // Uncomment line below for actual form submission
                // this.submit();
                
                // Reset for demo
                submitBtn.innerHTML = 'Lanjutkan ke Kelola Biometrik';
                submitBtn.disabled = false;
            }, 2000);
        });

        // Keyboard navigation (optional enhancement)
        let currentHighlight = -1;

        searchInput.addEventListener('keydown', function(e) {
            const items = dropdownList.querySelectorAll('.dropdown-item');
            
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                currentHighlight = Math.min(currentHighlight + 1, items.length - 1);
                updateHighlight(items);
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                currentHighlight = Math.max(currentHighlight - 1, 0);
                updateHighlight(items);
            } else if (e.key === 'Enter') {
                e.preventDefault();
                if (currentHighlight >= 0 && items[currentHighlight]) {
                    selectEmployee(items[currentHighlight]);
                }
            } else if (e.key === 'Escape') {
                hideDropdown();
                currentHighlight = -1;
            }
        });

        function updateHighlight(items) {
            items.forEach((item, index) => {
                if (index === currentHighlight) {
                    item.classList.add('selected');
                } else {
                    item.classList.remove('selected');
                }
            });
        }

        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            initializeDropdown();
            console.log('Form loaded with', employees.length, 'employees');
        });

        // Close dropdown when clicking outside
        document.addEventListener('click', function(e) {
            if (!e.target.closest('.search-container')) {
                hideDropdown();
            }
        });
    </script>
</body>
</html>