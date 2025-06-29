"""init clean

Revision ID: 55e6818efa30
Revises: 
Create Date: 2025-06-05 11:04:33.355410

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '55e6818efa30'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('user',
    sa.Column('user_id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('login_id', sa.String(length=20), nullable=False),
    sa.Column('password', sa.String(length=255), nullable=False),
    sa.Column('birthday', sa.Date(), nullable=True),
    sa.Column('phone', sa.String(length=15), nullable=True),
    sa.Column('study_time_mon', sa.Integer(), nullable=True),
    sa.Column('study_time_tue', sa.Integer(), nullable=True),
    sa.Column('study_time_wed', sa.Integer(), nullable=True),
    sa.Column('study_time_thu', sa.Integer(), nullable=True),
    sa.Column('study_time_fri', sa.Integer(), nullable=True),
    sa.Column('study_time_sat', sa.Integer(), nullable=True),
    sa.Column('study_time_sun', sa.Integer(), nullable=True),
    sa.PrimaryKeyConstraint('user_id'),
    sa.UniqueConstraint('login_id')
    )
    op.create_table('folders',
    sa.Column('folder_id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('name', sa.String(length=255), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('folder_id')
    )
    op.create_index(op.f('ix_folders_folder_id'), 'folders', ['folder_id'], unique=False)
    op.create_table('refresh_token',
    sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('token', sa.String(length=500), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.Column('expires_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('subject',
    sa.Column('subject_id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('field', sa.String(length=30), nullable=True),
    sa.Column('test_name', sa.String(length=50), nullable=True),
    sa.Column('test_date', sa.Date(), nullable=True),
    sa.Column('start_date', sa.Date(), nullable=True),
    sa.Column('end_date', sa.Date(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('subject_id')
    )
    op.create_table('timer',
    sa.Column('timer_id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('study_date', sa.Date(), nullable=False),
    sa.Column('total_minutes', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ),
    sa.PrimaryKeyConstraint('timer_id')
    )
    op.create_table('user_profile',
    sa.Column('profile_id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('name', sa.String(length=100), nullable=True),
    sa.Column('email', sa.String(length=100), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('profile_id'),
    sa.UniqueConstraint('user_id')
    )
    op.create_index(op.f('ix_user_profile_profile_id'), 'user_profile', ['profile_id'], unique=False)
    op.create_table('handwriting',
    sa.Column('handwriting_id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('folder_id', sa.Integer(), nullable=True),
    sa.Column('page_number', sa.Integer(), nullable=True),
    sa.Column('x', sa.Float(), nullable=True),
    sa.Column('y', sa.Float(), nullable=True),
    sa.Column('stroke_type', sa.String(length=20), nullable=True),
    sa.Column('color', sa.String(length=20), nullable=True),
    sa.Column('thickness', sa.Float(), nullable=True),
    sa.ForeignKeyConstraint(['folder_id'], ['folders.folder_id'], ),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('handwriting_id')
    )
    op.create_index(op.f('ix_handwriting_handwriting_id'), 'handwriting', ['handwriting_id'], unique=False)
    op.create_table('pdf_notes',
    sa.Column('pdf_id', sa.Integer(), nullable=False),
    sa.Column('title', sa.String(length=255), nullable=True),
    sa.Column('file_path', sa.Text(), nullable=True),
    sa.Column('total_pages', sa.Integer(), nullable=True),
    sa.Column('aspect_ratio', sa.Float(), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.Column('updated_at', sa.DateTime(), nullable=True),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('folder_id', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['folder_id'], ['folders.folder_id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('pdf_id')
    )
    op.create_index(op.f('ix_pdf_notes_pdf_id'), 'pdf_notes', ['pdf_id'], unique=False)
    op.create_table('plan',
    sa.Column('plan_id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('subject_id', sa.Integer(), nullable=True),
    sa.Column('plan_name', sa.String(length=255), nullable=True),
    sa.Column('plan_date', sa.Date(), nullable=True),
    sa.Column('complete', sa.Boolean(), nullable=True),
    sa.Column('plan_time', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['subject_id'], ['subject.subject_id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('plan_id')
    )
    op.create_table('pdf_pages',
    sa.Column('page_id', sa.Integer(), nullable=False),
    sa.Column('pdf_id', sa.Integer(), nullable=True),
    sa.Column('page_number', sa.Integer(), nullable=True),
    sa.Column('page_order', sa.Integer(), nullable=True),
    sa.Column('image_preview_url', sa.Text(), nullable=True),
    sa.Column('aspect_ratio', sa.Float(), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['pdf_id'], ['pdf_notes.pdf_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('page_id')
    )
    op.create_index(op.f('ix_pdf_pages_page_id'), 'pdf_pages', ['page_id'], unique=False)
    op.create_table('row_plan',
    sa.Column('row_plan_id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('row_plan_name', sa.String(length=50), nullable=False),
    sa.Column('type', sa.String(length=30), nullable=False),
    sa.Column('repetition', sa.Integer(), nullable=False),
    sa.Column('ranking', sa.Integer(), nullable=False),
    sa.Column('subject_id', sa.Integer(), nullable=False),
    sa.Column('plan_id', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['plan_id'], ['plan.plan_id'], ),
    sa.ForeignKeyConstraint(['subject_id'], ['subject.subject_id'], ),
    sa.ForeignKeyConstraint(['user_id'], ['user.user_id'], ),
    sa.PrimaryKeyConstraint('row_plan_id')
    )
    op.create_index(op.f('ix_row_plan_row_plan_id'), 'row_plan', ['row_plan_id'], unique=False)
    op.create_table('pdf_annotation',
    sa.Column('annotations_id', sa.Integer(), nullable=False),
    sa.Column('page_id', sa.Integer(), nullable=True),
    sa.Column('page_number', sa.Integer(), nullable=True),
    sa.Column('annotation_type', sa.String(length=50), nullable=True),
    sa.Column('data', sa.JSON(), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['page_id'], ['pdf_pages.page_id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('annotations_id')
    )
    op.create_index(op.f('ix_pdf_annotation_annotations_id'), 'pdf_annotation', ['annotations_id'], unique=False)
    # ### end Alembic commands ###


def downgrade() -> None:
    """Downgrade schema."""
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_index(op.f('ix_pdf_annotation_annotations_id'), table_name='pdf_annotation')
    op.drop_table('pdf_annotation')
    op.drop_index(op.f('ix_row_plan_row_plan_id'), table_name='row_plan')
    op.drop_table('row_plan')
    op.drop_index(op.f('ix_pdf_pages_page_id'), table_name='pdf_pages')
    op.drop_table('pdf_pages')
    op.drop_table('plan')
    op.drop_index(op.f('ix_pdf_notes_pdf_id'), table_name='pdf_notes')
    op.drop_table('pdf_notes')
    op.drop_index(op.f('ix_handwriting_handwriting_id'), table_name='handwriting')
    op.drop_table('handwriting')
    op.drop_index(op.f('ix_user_profile_profile_id'), table_name='user_profile')
    op.drop_table('user_profile')
    op.drop_table('timer')
    op.drop_table('subject')
    op.drop_table('refresh_token')
    op.drop_index(op.f('ix_folders_folder_id'), table_name='folders')
    op.drop_table('folders')
    op.drop_table('user')
    # ### end Alembic commands ###
