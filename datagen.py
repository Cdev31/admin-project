import csv
import random
from faker import Faker
import datetime
from dateutil.relativedelta import relativedelta
import os
import pandas as pd

fake = Faker('es_ES') # Datos en español
NUM_MEMBERS = 200
NUM_TRAINERS = 10
NUM_ROOMS = 5
NUM_CLASSES = 15
NUM_SCHEDULES = 50
NUM_RESERVATIONS = 300
NUM_PAYMENTS = 400

OUTPUT_DIR = 'C:/SQL_Backups/DataImport' # Carpeta donde SQL Server buscará los archivos
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

print(f"Generando datos en {OUTPUT_DIR}...")

# Función auxiliar para guardar CSVs con el salto de línea correcto (\n) compatible con BULK INSERT '0x0a'
def save_csv(df, filename):
    df.to_csv(f'{OUTPUT_DIR}/{filename}', index=False, header=True, lineterminator='\n')

# 1. Membership Types
membership_types = [
    (1, 'Básica', 'Acceso solo a sala de pesas', 1, 19.99, 0, 1),
    (2, 'VIP', 'Acceso total + clases grupales', 1, 29.99, 1, 1),
    (3, 'Trimestral', 'Plan de 3 meses con descuento', 3, 49.99, 0, 1),
    (4, 'Trimestral VIP', 'Plan de 3 meses VIP con descuento', 3, 79.99, 1, 1),
    (5, 'Anual', 'Plan anual con descuento', 12, 179.99, 0, 1),
    (6, 'Anual VIP', 'Todo incluido anual', 12, 299.99, 1, 1)
]
df_mt = pd.DataFrame(membership_types, columns=['membership_type_id', 'type_name', 'description', 'duration_months', 'price', 'is_unlimited', 'is_active'])
save_csv(df_mt, 'membership_type.csv')

# 2. Payment Methods
payment_methods = [
    (1, 'Efectivo', 1), (2, 'Tarjeta Crédito', 1), (3, 'Transferencia', 1), (4, 'PayPal', 1)
]
df_pm = pd.DataFrame(payment_methods, columns=['payment_method_id', 'method_name', 'is_active'])
save_csv(df_pm, 'payment_method.csv')

# 3. Rooms
rooms = []
for i in range(1, NUM_ROOMS + 1):
    rooms.append((i, f'Sala {fake.word().capitalize()}', random.randint(5, 20), 1))
df_rooms = pd.DataFrame(rooms, columns=['room_id', 'room_name', 'capacity', 'is_active'])
save_csv(df_rooms, 'room.csv')

# 4. Trainers
trainers = []
for i in range(1, NUM_TRAINERS + 1):
    trainers.append((
        i, fake.first_name(), fake.last_name(), 
        random.choice(['Yoga', 'Crossfit', 'Musculación', 'Pilates', 'Zumba']),
        fake.phone_number()[:15], fake.email(), random.choices([0, 1], weights=[0.1, 0.9], k=1)[0] # 90% activos
    ))
df_trainers = pd.DataFrame(trainers, columns=['trainer_id', 'first_name', 'last_name', 'specialty', 'phone', 'email', 'is_active'])
save_csv(df_trainers, 'trainer.csv')

# 5. Members
members = []
for i in range(1, NUM_MEMBERS + 1):
    reg_date = fake.date_between(start_date='-2y', end_date='today')
    members.append((
        i, 
        f'M{i:05d}',
        fake.first_name(), 
        fake.last_name(), 
        fake.ssn()[:15],
        fake.date_of_birth(minimum_age=16, maximum_age=70),
        fake.phone_number()[:15],
        fake.email(), 
        reg_date,
        random.choices([0, 1], weights=[0.2, 0.8], k=1)[0] # 80% activos
    ))
df_members = pd.DataFrame(members, columns=['member_id', 'member_code', 'first_name', 'last_name', 'identity_document', 'birth_date', 'phone', 'email', 'registration_date', 'is_active'])
save_csv(df_members, 'member.csv')

# 6. Member Membership (Relación)
member_memberships = []
mm_id_counter = 1
for m in members:
    m_id = m[0]
    m_reg_date = m[8] # Fecha registro socio
    # Asignar una membresia aleatoria
    m_type = random.choice(membership_types)
    start_date = m_reg_date
    end_date = start_date + relativedelta(months=1 * m_type[3])
    
    member_memberships.append((
        mm_id_counter, m_id, m_type[0], start_date, end_date, 1
    ))
    mm_id_counter += 1
df_mm = pd.DataFrame(member_memberships, columns=['member_membership_id', 'member_id', 'membership_type_id', 'start_date', 'end_date', 'is_active'])
save_csv(df_mm, 'member_membership.csv')

# 7. Classes
classes = []
class_types = ['Group', 'Personal']
for i in range(1, NUM_CLASSES + 1):
    classes.append((
        i, f'Clase de {random.choice(['Aeróbicos', 'Pilates', 'Pesas', 'Cardio']).capitalize()}', fake.sentence(), 
        random.choice(class_types), random.choice([30, 45, 60, 90]), 
        random.randint(5, 20)
    ))
df_classes = pd.DataFrame(classes, columns=['class_id', 'class_name', 'description', 'class_type', 'duration_minutes', 'max_capacity'])
save_csv(df_classes, 'class.csv')

# 8. Class Schedule
schedules = []
for i in range(1, NUM_SCHEDULES + 1):
    start_dt = fake.date_time_between(start_date='-1M', end_date='+1M')
    end_dt = start_dt + datetime.timedelta(minutes=60)
    schedules.append((
        i, random.randint(1, NUM_CLASSES), random.randint(1, NUM_TRAINERS), 
        random.randint(1, NUM_ROOMS), start_dt, end_dt, random.randint(10, 20)
    ))
df_schedules = pd.DataFrame(schedules, columns=['class_schedule_id', 'class_id', 'trainer_id', 'room_id', 'start_datetime', 'end_datetime', 'max_capacity'])
save_csv(df_schedules, 'class_schedule.csv')

# 9. Reservations
reservations = []
seen_res = set()
for i in range(1, NUM_RESERVATIONS + 1):
    mem_id = random.randint(1, NUM_MEMBERS)
    sched_id = random.randint(1, NUM_SCHEDULES)
    
    if (mem_id, sched_id) not in seen_res:
        seen_res.add((mem_id, sched_id))
        status = random.choice(['Reserved', 'Cancelled', 'Completed'])
        attended = 1 if status == 'Completed' else 0
        reservations.append((
            i, mem_id, sched_id, fake.date_time_between(start_date='-1M', end_date='now'),
            status, attended
        ))
df_reservations = pd.DataFrame(reservations, columns=['reservation_id', 'member_id', 'class_schedule_id', 'reservation_date', 'reservation_status', 'attended'])
save_csv(df_reservations, 'reservation.csv')

# 10. Payments
# Creamos un diccionario para buscar rápidamente el precio según el ID del tipo de membresía
price_map = {mt[0]: mt[4] for mt in membership_types}

payments = []
for i in range(1, NUM_PAYMENTS + 1):
    mem_ship = random.choice(member_memberships)
    type_id = mem_ship[2]
    amount = price_map[type_id]

    payments.append((
        i, mem_ship[1], mem_ship[0], random.randint(1, 4),
        fake.date_time_between(start_date='-6M', end_date='now'),
        amount,
        mem_ship[3], mem_ship[4],
        fake.bothify(text='REF-????-########')
    ))
df_payments = pd.DataFrame(payments, columns=['payment_id', 'member_id', 'member_membership_id', 'payment_method_id', 'payment_date', 'amount', 'period_start', 'period_end', 'reference'])
save_csv(df_payments, 'payment.csv')

print("¡Archivos CSV generados exitosamente!")