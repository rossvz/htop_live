use std::{
    fs::{self},
    thread::{self, sleep},
    time::Duration,
};

use sysinfo::{CpuExt, System, SystemExt};

#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

fn write_cpu_usage_file(sys: &mut System) -> std::io::Result<()> {
    sys.refresh_cpu();
    let usage = sys.cpus().iter().fold("".to_string(), |acc, c| {
        format!("{}\n{}:{:?}", acc, c.name(), c.cpu_usage())
    });

    fs::write("usage", usage)?;
    Ok(())
}

#[rustler::nif]
pub fn loop_cpu_check() {
    let mut sys = System::new_all();
    thread::spawn(move || loop {
        let _ = write_cpu_usage_file(&mut sys);
        sleep(Duration::from_millis(500))
    });

    ()
}

rustler::init!("Elixir.Htop.SystemInfo", [add, loop_cpu_check]);
