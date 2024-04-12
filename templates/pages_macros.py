{% macro get_all(model) %}
{% if 'postgres' in cookiecutter.db_resource or 'mysql' in cookiecutter.db_resource %}
all_{{ model|lower }}s = db.session.execute(db.select(models.{{ model|capitalize }})).scalars().all()
{% endif %}
{% if 'mongodb' in cookiecutter.db_resource %}
all_{{ model|lower }}s = models.{{ model|capitalize }}.objects.all()
{% endif %}
{% endmacro %}

{% macro get_one(model) %}
{% if 'postgres' in cookiecutter.db_resource or 'mysql' in cookiecutter.db_resource %}
{{model|lower}} = db.get_or_404(models.{{model|capitalize}}, pk)
{% endif %}
{% if 'mongodb' in cookiecutter.db_resource %}
{{model|lower}} = models.{{model|capitalize}}.objects.get(pk=pk)
{% endif %}
{% endmacro %}
