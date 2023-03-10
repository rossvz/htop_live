use std::{thread::sleep, time::Duration};

use sysinfo::{CpuExt, System, SystemExt};

#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[derive(Debug)]
struct Info {
    num_cores: usize,
    cpus: Vec<f32>,
    global_usage: f32,
}
impl Info {
    fn new() -> Self {
        Info {
            num_cores: 0,
            cpus: Vec::new(),
            global_usage: 0.0,
        }
    }
}

fn refresh_cpus(mut sys: System, mut info: Info) {
    sys.refresh_cpu();
    let cpu_data = sys.cpus().iter().map(|c| c.cpu_usage()).collect();

    info.cpus = cpu_data;
    info.global_usage = sys.global_cpu_info().cpu_usage();
    info.num_cores = sys.physical_core_count().unwrap();

    println!("{info:?}");
}

#[rustler::nif]
pub fn get_cpu() -> Vec<String> {
    let mut sys = System::new_all();
    // let _info = Info::new();

    // let count = 0;

    // refresh_cpus(sys, info)

    sys.refresh_cpu();
    sleep(Duration::from_millis(200));
    sys.refresh_cpu();
    sys.cpus()
        .iter()
        .map(|c| format!("{}:{:?}", c.name(), c.cpu_usage()))
        .collect()
}

rustler::init!("Elixir.Htop.SystemInfo", [add, get_cpu]);
