import cdstoolbox as ct

@ct.application()
@ct.output.download()
def get_daily_max(variable, year, month):

    # Retrieve the hourly 2m temperature over Lima for 20230101
    temperature = ct.catalogue.retrieve(
        'reanalysis-era5-single-levels',
        {
            'variable': variable,
            'product_type': 'reanalysis',
            'year': year,
            'month': month,
            'day': list(range(1, 31 + 1)),
            'time': [
                '00:00', '01:00', '02:00', '03:00', '04:00', '05:00',
                '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
                '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
                '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'
            ],
            'grid': [0.25, 0.25],
            'area': [-11., -78., -13., -76.], # only for Lima bbox
        }
    )

    # Compute the daily mean temperature over Europe
    temperature_daily_max = ct.cube.resample(temperature, freq='day', how='max')

    return temperature_daily_max
