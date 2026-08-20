# 1. Получение актуального ID образа для ВМ
data "yandex_compute_image" "vm_image" {
  family = var.vm_image_family
}

# 2. Создание VPC сети
resource "yandex_vpc_network" "my_network" {
  name = "my-vpc"
}

# 3. Создание публичной подсети
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.zone
  network_id     = yandex_vpc_network.my_network.id
  v4_cidr_blocks = [var.public_subnet_cidr]
}

# 4. Создание приватной подсети (с привязкой таблицы маршрутизации)
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.zone
  network_id     = yandex_vpc_network.my_network.id
  v4_cidr_blocks = [var.private_subnet_cidr]
  route_table_id = yandex_vpc_route_table.private_route.id
}

# 5. Создание NAT-инстанса (прерываемый, 20% CPU)
resource "yandex_compute_instance" "nat_instance" {
  name = "nat-instance"
  zone = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.nat_instance_image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    ip_address = "192.168.10.254"
    nat        = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
    user-data = <<-EOF
      #!/bin/bash
      sysctl -w net.ipv4.ip_forward=1
      iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
      iptables -A FORWARD -i eth0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
      iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT
    EOF
  }

  scheduling_policy {
    preemptible = true
  }

  timeouts {
    create = "5m"
  }
}

# 6. Создание таблицы маршрутизации
resource "yandex_vpc_route_table" "private_route" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.my_network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat_instance.network_interface.0.ip_address
  }
}

# 7. Создание публичной тестовой ВМ (прерываемая, 20% CPU)
resource "yandex_compute_instance" "vm_public" {
  name = "vm-public"
  zone = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_image.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  scheduling_policy {
    preemptible = true
  }

  timeouts {
    create = "5m"
  }
}

# 8. Создание приватной тестовой ВМ (прерываемая, 20% CPU)
resource "yandex_compute_instance" "vm_private" {
  name = "vm-private"
  zone = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_image.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  scheduling_policy {
    preemptible = true
  }

  timeouts {
    create = "5m"
  }
}

# 9. Вывод IP-адресов для проверки
output "vm_public_ip" {
  value = yandex_compute_instance.vm_public.network_interface.0.nat_ip_address
}

output "vm_private_ip" {
  value = yandex_compute_instance.vm_private.network_interface.0.ip_address
}

output "nat_instance_ip" {
  value = yandex_compute_instance.nat_instance.network_interface.0.nat_ip_address
}

output "vm_image_id_used" {
  description = "ID of the VM image that was used"
  value       = data.yandex_compute_image.vm_image.image_id
}
