/*
 * Linux IBM/Lenovo ScrollPoint mouse driver
 *
 * Copyright (c) 2012 Peter De Wachter <pdewacht@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <linux/device.h>
#include <linux/hid.h>
#include <linux/module.h>

#include "hid-ids.h"

static int scrollpoint_input_mapping(struct hid_device *hdev,
		struct hid_input *hi, struct hid_field *field,
		struct hid_usage *usage, unsigned long **bit, int *max)
{
	if (usage->hid == HID_GD_Z) {
		hid_map_usage(hi, usage, bit, max, EV_REL, REL_HWHEEL);
		return 1;
	}
	return 0;
}

static const struct hid_device_id scrollpoint_devices[] = {
	{ HID_USB_DEVICE(USB_VENDOR_ID_LENOVO,
		USB_DEVICE_ID_LENOVO_SP) },
	{ }
};
MODULE_DEVICE_TABLE(hid, scrollpoint_devices);

static struct hid_driver scrollpoint_driver = {
	.name = "scrollpoint",
	.id_table = scrollpoint_devices,
	.input_mapping = scrollpoint_input_mapping
};

static int __init scrollpoint_init(void)
{
	return hid_register_driver(&scrollpoint_driver);
}

static void __exit scrollpoint_exit(void)
{
	hid_unregister_driver(&scrollpoint_driver);
}

module_init(scrollpoint_init);
module_exit(scrollpoint_exit);

//This is completely based off code from Peter De Wachter
MODULE_AUTHOR("Chethan Pandarinath");
MODULE_DESCRIPTION("Lenovo ScrollPoint mouse driver");
MODULE_LICENSE("GPL");
